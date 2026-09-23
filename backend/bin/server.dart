import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

const _jwtSecret = 'rit-hostel-demo-secret';

final _dbFile = _resolveDbFile();

File _resolveDbFile() {
  // The backend is often started from the repo root (`dart run backend/bin/server.dart`)
  // or from inside `backend/`. The DB path must be stable in both cases.
  final candidates = <String>[
    'backend/data/db.json',
    'data/db.json',
  ];

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file;
  }

  // Default to the first (preferred) location even if it doesn't exist yet.
  return File(candidates.first);
}

const _defaultAdminEmail = 'admin@rit-hostel.local';
const _defaultAdminPassword = 'admin1234';

Future<void> main() async {
  await _ensureDatabase();

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8081;
  final hostEnv = Platform.environment['HOST']?.trim();
  final host = hostEnv != null && hostEnv.isNotEmpty
      ? InternetAddress(hostEnv)
      : InternetAddress.loopbackIPv4;

  final app = Router()
    ..get('/api/health', _healthHandler)
    ..get('/api/hostels', _hostelsHandler)
    ..post('/api/auth/register', _registerHandler)
    ..post('/api/auth/login', _loginHandler)
    ..post('/api/auth/forgot-password', _forgotPasswordHandler)
    ..post('/api/contact', _contactHandler)
    ..post('/api/admissions', _admissionHandler)
    ..get('/api/me', _meHandler)
    ..get('/api/my/complaints', _myComplaintsHandler)
    ..get('/api/my/checkins', _myCheckinsHandler)
    ..get('/api/my/room', _myRoomHandler)
    ..get('/api/admin/users', _adminUsersHandler)
    ..patch('/api/admin/users/<id>', _adminUpdateUserHandler)
    ..get('/api/admin/dashboard', _adminDashboardHandler)
    ..get('/api/admin/rooms', _adminRoomsListHandler)
    ..post('/api/admin/rooms', _adminRoomsCreateHandler)
    ..patch('/api/admin/rooms/<id>', _adminRoomsUpdateHandler)
    ..post('/api/complaints', _complaintCreateHandler)
    ..get('/api/admin/complaints', _adminComplaintsListHandler)
    ..patch('/api/admin/complaints/<id>', _adminComplaintsUpdateHandler)
    ..get('/api/admin/checkins', _adminCheckinsListHandler)
    ..post('/api/admin/checkin', _adminCheckInHandler)
    ..post('/api/admin/checkout', _adminCheckOutHandler);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(_errorMiddleware())
      .addHandler(app.call);

  final server = await io.serve(handler, host, port);
  stdout.writeln(
    'Hostel backend running on http://${server.address.address}:${server.port}',
  );
}

Future<Response> _healthHandler(Request request) async {
  return _json({
    'ok': true,
    'service': 'hostel_app_backend',
    'time': DateTime.now().toIso8601String(),
  });
}

Future<Response> _hostelsHandler(Request request) async {
  final db = await _readDb();
  return _json({'hostels': db['hostels']});
}

Future<Response> _registerHandler(Request request) async {
  final body = await _readJson(request);
  final name = _requiredString(body, 'name');
  final email = _requiredString(body, 'email').toLowerCase();
  final password = _requiredString(body, 'password');
  final gender = _requiredString(body, 'gender');
  final age = _requiredString(body, 'age');
  final phone = _requiredString(body, 'phone');

  final db = await _readDb();
  final users = List<Map<String, dynamic>>.from(db['users'] as List);

  final exists = users.any((u) => (u['email'] as String).toLowerCase() == email);
  if (exists) {
    return _error('User already exists with this email', HttpStatus.conflict);
  }

  final user = {
    'id': _id(),
    'name': name,
    'email': email,
    'passwordHash': _hashPassword(password),
    'gender': gender,
    'age': age,
    'phone': phone,
    'role': 'student',
    'createdAt': DateTime.now().toIso8601String(),
  };

  users.add(user);
  db['users'] = users;
  await _writeDb(db);

  final token = _tokenForUser(user);
  return _json({
    'message': 'Registration successful',
    'token': token,
    'user': _safeUser(user),
  }, statusCode: HttpStatus.created);
}

Future<Response> _loginHandler(Request request) async {
  final body = await _readJson(request);
  final email = _requiredString(body, 'email').toLowerCase();
  final password = _requiredString(body, 'password');

  final db = await _readDb();
  final users = List<Map<String, dynamic>>.from(db['users'] as List);
  final user = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u != null && (u['email'] as String).toLowerCase() == email,
        orElse: () => null,
      );

  if (user == null || user['passwordHash'] != _hashPassword(password)) {
    return _error('Invalid email or password', HttpStatus.unauthorized);
  }

  final token = _tokenForUser(user);
  return _json({
    'message': 'Login successful',
    'token': token,
    'user': _safeUser(user),
  });
}

Future<Response> _forgotPasswordHandler(Request request) async {
  final body = await _readJson(request);
  final email = _requiredString(body, 'email').toLowerCase();

  final db = await _readDb();
  final users = List<Map<String, dynamic>>.from(db['users'] as List);
  final exists = users.any((u) => (u['email'] as String).toLowerCase() == email);

  return _json({
    'message': exists
        ? 'Password reset request recorded. Please contact the hostel office to reset it.'
        : 'No user found with that email.',
    'found': exists,
  });
}

Future<Response> _contactHandler(Request request) async {
  final body = await _readJson(request);
  final name = _requiredString(body, 'name');
  final email = _requiredString(body, 'email');
  final phone = _requiredString(body, 'phone');
  final message = _requiredString(body, 'message');

  final db = await _readDb();
  final contacts = List<Map<String, dynamic>>.from(db['contacts'] as List);
  contacts.add({
    'id': _id(),
    'name': name,
    'email': email,
    'phone': phone,
    'message': message,
    'createdAt': DateTime.now().toIso8601String(),
  });
  db['contacts'] = contacts;
  await _writeDb(db);

  return _json({
    'message': 'Contact form submitted successfully',
  }, statusCode: HttpStatus.created);
}

Future<Response> _admissionHandler(Request request) async {
  final body = await _readJson(request);
  final fullName = _requiredString(body, 'fullName');
  final collegeId = _requiredString(body, 'collegeId');
  final email = _requiredString(body, 'email');
  final phone = _requiredString(body, 'phone');
  final course = _requiredString(body, 'course');
  final yearOfStudy = _requiredString(body, 'yearOfStudy');
  final department = _requiredString(body, 'department');
  final hostelType = _requiredString(body, 'hostelType');
  final roomType = _requiredString(body, 'roomType');

  final db = await _readDb();
  final admissions = List<Map<String, dynamic>>.from(db['admissions'] as List);
  admissions.add({
    'id': _id(),
    'fullName': fullName,
    'collegeId': collegeId,
    'email': email,
    'phone': phone,
    'course': course,
    'yearOfStudy': yearOfStudy,
    'department': department,
    'hostelType': hostelType,
    'roomType': roomType,
    'createdAt': DateTime.now().toIso8601String(),
  });
  db['admissions'] = admissions;
  await _writeDb(db);

  return _json({
    'message': 'Admission form submitted successfully',
  }, statusCode: HttpStatus.created);
}

Future<Response> _meHandler(Request request) async {
  try {
    final userId = _requireAuthUserId(request);

    final db = await _readDb();
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final user = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u != null && u['id'] == userId,
          orElse: () => null,
        );

    if (user == null) {
      return _error('User not found', HttpStatus.notFound);
    }

    return _json({'user': _safeUser(user)});
  } on JWTException {
    return _error('Invalid token', HttpStatus.unauthorized);
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminUsersHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final db = await _readDb();
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final safeUsers = users.map(_safeUser).toList();
    return _json({'users': safeUsers});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminUpdateUserHandler(Request request, String id) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);

    final db = await _readDb();
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final index = users.indexWhere((u) => u['id']?.toString() == id);
    if (index < 0) {
      return _error('User not found', HttpStatus.notFound);
    }

    final user = Map<String, dynamic>.from(users[index]);
    if (body.containsKey('role')) {
      final role = body['role']?.toString().trim().toLowerCase();
      if (role != 'student' && role != 'admin') {
        return _error('Invalid role', HttpStatus.badRequest);
      }
      user['role'] = role;
    }
    if (body.containsKey('phone')) {
      user['phone'] = body['phone']?.toString().trim() ?? '';
    }
    if (body.containsKey('name')) {
      user['name'] = body['name']?.toString().trim() ?? '';
    }

    users[index] = user;
    db['users'] = users;
    await _writeDb(db);

    return _json({'user': _safeUser(user)});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminDashboardHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final db = await _readDb();
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final complaints = List<Map<String, dynamic>>.from(db['complaints'] as List);
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);

    final studentsCount =
        users.where((u) => (u['role']?.toString() ?? 'student') == 'student').length;
    final adminsCount =
        users.where((u) => (u['role']?.toString() ?? 'student') == 'admin').length;
    final roomsCount = rooms.length;
    final activeCheckins =
        checkins.where((c) => (c['checkOutAt']?.toString() ?? '').isEmpty).length;
    final openComplaints = complaints.where((c) {
      final s = (c['status']?.toString() ?? 'open').toLowerCase();
      return s != 'resolved' && s != 'closed';
    }).length;

    return _json({
      'counts': {
        'students': studentsCount,
        'admins': adminsCount,
        'rooms': roomsCount,
        'activeCheckins': activeCheckins,
        'openComplaints': openComplaints,
      },
    });
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminRoomsListHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final db = await _readDb();
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    return _json({'rooms': rooms});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminRoomsCreateHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);

    final building = _requiredString(body, 'building');
    final roomNo = _requiredString(body, 'roomNo');
    final type = _requiredString(body, 'type');
    final status = (body['status']?.toString().trim().isEmpty ?? true)
        ? 'available'
        : body['status']!.toString().trim();
    final floor = int.tryParse(body['floor']?.toString() ?? '') ?? 0;
    final capacity = int.tryParse(body['capacity']?.toString() ?? '') ?? 1;

    final db = await _readDb();
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);

    rooms.add({
      'id': _id(),
      'building': building,
      'floor': floor,
      'roomNo': roomNo,
      'capacity': capacity,
      'occupiedCount': 0,
      'type': type,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
    });

    db['rooms'] = rooms;
    await _writeDb(db);
    return _json({'rooms': rooms}, statusCode: HttpStatus.created);
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminRoomsUpdateHandler(Request request, String id) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);

    final db = await _readDb();
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final index = rooms.indexWhere((r) => r['id']?.toString() == id);
    if (index < 0) return _error('Room not found', HttpStatus.notFound);

    final room = Map<String, dynamic>.from(rooms[index]);
    if (body.containsKey('building')) room['building'] = body['building']?.toString() ?? '';
    if (body.containsKey('roomNo')) room['roomNo'] = body['roomNo']?.toString() ?? '';
    if (body.containsKey('type')) room['type'] = body['type']?.toString() ?? '';
    if (body.containsKey('status')) room['status'] = body['status']?.toString() ?? '';
    if (body.containsKey('floor')) {
      room['floor'] = int.tryParse(body['floor']?.toString() ?? '') ?? 0;
    }
    if (body.containsKey('capacity')) {
      room['capacity'] = int.tryParse(body['capacity']?.toString() ?? '') ?? 1;
    }

    rooms[index] = room;
    db['rooms'] = rooms;
    await _writeDb(db);
    return _json({'room': room});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _complaintCreateHandler(Request request) async {
  try {
    final userId = _requireAuthUserId(request);
    final body = await _readJson(request);
    final title = _requiredString(body, 'title');
    final description = _requiredString(body, 'description');

    final db = await _readDb();
    final complaints = List<Map<String, dynamic>>.from(db['complaints'] as List);
    final complaint = {
      'id': _id(),
      'userId': userId,
      'title': title,
      'description': description,
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
    };
    complaints.add(complaint);
    db['complaints'] = complaints;
    await _writeDb(db);
    return _json({'complaint': complaint}, statusCode: HttpStatus.created);
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _myComplaintsHandler(Request request) async {
  try {
    final userId = _requireAuthUserId(request);
    final db = await _readDb();
    final complaints = List<Map<String, dynamic>>.from(db['complaints'] as List);
    final mine = complaints
        .where((c) => c['userId']?.toString() == userId)
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    mine.sort((a, b) => (b['createdAt']?.toString() ?? '').compareTo(a['createdAt']?.toString() ?? ''));
    return _json({'complaints': mine});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _myCheckinsHandler(Request request) async {
  try {
    final userId = _requireAuthUserId(request);
    final db = await _readDb();
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final roomsById = <String, Map<String, dynamic>>{
      for (final r in rooms) r['id']?.toString() ?? '': r,
    };

    final mine = checkins
        .where((c) => c['userId']?.toString() == userId)
        .map((c) {
          final m = Map<String, dynamic>.from(c);
          final room = roomsById[m['roomId']?.toString() ?? ''];
          if (room != null) m['room'] = room;
          return m;
        })
        .toList();
    mine.sort((a, b) => (b['checkInAt']?.toString() ?? '').compareTo(a['checkInAt']?.toString() ?? ''));
    return _json({'checkins': mine});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _myRoomHandler(Request request) async {
  try {
    final userId = _requireAuthUserId(request);
    final db = await _readDb();
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final roomsById = <String, Map<String, dynamic>>{
      for (final r in rooms) r['id']?.toString() ?? '': r,
    };

    final active = checkins.cast<Map<String, dynamic>?>().firstWhere(
          (c) =>
              c != null &&
              c['userId']?.toString() == userId &&
              (c['checkOutAt']?.toString() ?? '').isEmpty,
          orElse: () => null,
        );

    if (active == null) {
      return _json({'activeCheckin': null, 'room': null});
    }

    final room = roomsById[active['roomId']?.toString() ?? ''];
    return _json({
      'activeCheckin': active,
      'room': room,
    });
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminComplaintsListHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final db = await _readDb();
    final complaints = List<Map<String, dynamic>>.from(db['complaints'] as List);
    final users = List<Map<String, dynamic>>.from(db['users'] as List);

    final byId = <String, Map<String, dynamic>>{
      for (final u in users) u['id']?.toString() ?? '': u,
    };

    final enriched = complaints.map((c) {
      final m = Map<String, dynamic>.from(c);
      final user = byId[m['userId']?.toString() ?? ''];
      if (user != null) {
        m['user'] = _safeUser(user);
      }
      return m;
    }).toList();

    return _json({'complaints': enriched});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminComplaintsUpdateHandler(Request request, String id) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);
    final status = body['status']?.toString().trim().toLowerCase();
    if (status == null || status.isEmpty) {
      return _error('Missing field: status', HttpStatus.badRequest);
    }

    final db = await _readDb();
    final complaints = List<Map<String, dynamic>>.from(db['complaints'] as List);
    final index = complaints.indexWhere((c) => c['id']?.toString() == id);
    if (index < 0) return _error('Complaint not found', HttpStatus.notFound);

    final complaint = Map<String, dynamic>.from(complaints[index]);
    complaint['status'] = status;
    if (status == 'resolved' || status == 'closed') {
      complaint['resolvedAt'] = DateTime.now().toIso8601String();
    }
    complaints[index] = complaint;
    db['complaints'] = complaints;
    await _writeDb(db);
    return _json({'complaint': complaint});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminCheckinsListHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final db = await _readDb();
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);

    final usersById = <String, Map<String, dynamic>>{
      for (final u in users) u['id']?.toString() ?? '': u,
    };
    final roomsById = <String, Map<String, dynamic>>{
      for (final r in rooms) r['id']?.toString() ?? '': r,
    };

    final enriched = checkins.map((c) {
      final m = Map<String, dynamic>.from(c);
      final user = usersById[m['userId']?.toString() ?? ''];
      final room = roomsById[m['roomId']?.toString() ?? ''];
      if (user != null) m['user'] = _safeUser(user);
      if (room != null) m['room'] = room;
      return m;
    }).toList();

    return _json({'checkins': enriched});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminCheckInHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);
    final userId = _requiredString(body, 'userId');
    final roomId = _requiredString(body, 'roomId');

    final db = await _readDb();
    final users = List<Map<String, dynamic>>.from(db['users'] as List);
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);

    final user = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u != null && u['id']?.toString() == userId,
          orElse: () => null,
        );
    if (user == null) return _error('User not found', HttpStatus.notFound);

    final roomIndex = rooms.indexWhere((r) => r['id']?.toString() == roomId);
    if (roomIndex < 0) return _error('Room not found', HttpStatus.notFound);

    final room = Map<String, dynamic>.from(rooms[roomIndex]);
    final capacity = int.tryParse(room['capacity']?.toString() ?? '') ?? 1;
    final occupied = int.tryParse(room['occupiedCount']?.toString() ?? '') ?? 0;
    if (occupied >= capacity) {
      return _error('Room is full', HttpStatus.conflict);
    }

    final alreadyActive = checkins.any(
      (c) =>
          c['userId']?.toString() == userId &&
          (c['checkOutAt']?.toString() ?? '').isEmpty,
    );
    if (alreadyActive) {
      return _error('User already checked-in', HttpStatus.conflict);
    }

    final checkin = {
      'id': _id(),
      'userId': userId,
      'roomId': roomId,
      'checkInAt': DateTime.now().toIso8601String(),
      'checkOutAt': '',
    };
    checkins.add(checkin);
    room['occupiedCount'] = occupied + 1;
    rooms[roomIndex] = room;

    db['checkins'] = checkins;
    db['rooms'] = rooms;
    await _writeDb(db);
    return _json({'checkin': checkin}, statusCode: HttpStatus.created);
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<Response> _adminCheckOutHandler(Request request) async {
  try {
    await _requireAdmin(request);
    final body = await _readJson(request);
    final checkinId = _requiredString(body, 'checkinId');

    final db = await _readDb();
    final rooms = List<Map<String, dynamic>>.from(db['rooms'] as List);
    final checkins = List<Map<String, dynamic>>.from(db['checkins'] as List);

    final checkinIndex = checkins.indexWhere((c) => c['id']?.toString() == checkinId);
    if (checkinIndex < 0) return _error('Check-in not found', HttpStatus.notFound);

    final checkin = Map<String, dynamic>.from(checkins[checkinIndex]);
    if ((checkin['checkOutAt']?.toString() ?? '').isNotEmpty) {
      return _error('Already checked-out', HttpStatus.conflict);
    }
    checkin['checkOutAt'] = DateTime.now().toIso8601String();
    checkins[checkinIndex] = checkin;

    final roomId = checkin['roomId']?.toString() ?? '';
    final roomIndex = rooms.indexWhere((r) => r['id']?.toString() == roomId);
    if (roomIndex >= 0) {
      final room = Map<String, dynamic>.from(rooms[roomIndex]);
      final occupied = int.tryParse(room['occupiedCount']?.toString() ?? '') ?? 0;
      room['occupiedCount'] = occupied > 0 ? occupied - 1 : 0;
      rooms[roomIndex] = room;
    }

    db['checkins'] = checkins;
    db['rooms'] = rooms;
    await _writeDb(db);
    return _json({'checkin': checkin});
  } on _AuthException catch (e) {
    return _error(e.message, e.statusCode);
  }
}

Future<void> _ensureDatabase() async {
  if (!_dbFile.parent.existsSync()) {
    _dbFile.parent.createSync(recursive: true);
  }
  if (!_dbFile.existsSync()) {
    final seed = {
      'users': <Map<String, dynamic>>[],
      'contacts': <Map<String, dynamic>>[],
      'admissions': <Map<String, dynamic>>[],
      'complaints': <Map<String, dynamic>>[],
      'rooms': <Map<String, dynamic>>[],
      'checkins': <Map<String, dynamic>>[],
      'hostels': [
        {
          'id': 'indra',
          'name': 'Indra (New Boys Hostel)',
          'type': 'Boys',
          'roomType': 'Double Occupancy',
          'summary': 'Modern mess, WiFi, laundry, and study room',
        },
        {
          'id': 'boys-abcd',
          'name': 'Boys Hostel (A, B, C, D)',
          'type': 'Boys',
          'roomType': 'Single / Double Occupancy',
          'summary': 'Security, attached bathroom, wardrobe, and campus video',
        },
        {
          'id': 'girls-fairy',
          'name': 'Girls Hostel (Fairy)',
          'type': 'Girls',
          'roomType': 'Triple Occupancy',
          'summary': 'Common study room, WiFi, and reading lamp',
        },
        {
          'id': 'girls-haripriya',
          'name': 'Girls Hostel (Haripriya)',
          'type': 'Girls',
          'roomType': 'Double Occupancy',
          'summary': 'Recreation room, WiFi, and reading lamp',
        },
      ],
    };
    await _writeDb(seed);
  }

  await _migrateDb();
}

Future<Map<String, dynamic>> _readDb() async {
  final raw = await _dbFile.readAsString();
  return Map<String, dynamic>.from(jsonDecode(raw) as Map);
}

Future<void> _writeDb(Map<String, dynamic> db) async {
  await _dbFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(db),
  );
}

Future<Map<String, dynamic>> _readJson(Request request) async {
  try {
    final raw = await request.readAsString();
    if (raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  } catch (_) {
    throw const FormatException('Invalid JSON body');
  }
}

Response _json(Map<String, dynamic> body, {int statusCode = HttpStatus.ok}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
  );
}

Response _error(String message, int statusCode) {
  return _json({'message': message}, statusCode: statusCode);
}

String _requiredString(Map<String, dynamic> body, String key) {
  final value = body[key];
  if (value == null || value.toString().trim().isEmpty) {
    throw FormatException('Missing field: $key');
  }
  return value.toString().trim();
}

String _hashPassword(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}

String _tokenForUser(Map<String, dynamic> user) {
  final jwt = JWT({
    'sub': user['id'],
    'email': user['email'],
    'name': user['name'],
    'role': user['role']?.toString() ?? 'student',
  });
  return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(days: 7));
}

Map<String, dynamic> _safeUser(Map<String, dynamic> user) {
  return {
    'id': user['id'],
    'name': user['name'],
    'email': user['email'],
    'gender': user['gender'],
    'age': user['age'],
    'phone': user['phone'],
    'role': user['role']?.toString() ?? 'student',
  };
}

String _id() => DateTime.now().microsecondsSinceEpoch.toString();

Future<void> _migrateDb() async {
  final db = await _readDb();
  var changed = false;

  void ensureList(String key) {
    if (db[key] is! List) {
      db[key] = <Map<String, dynamic>>[];
      changed = true;
    }
  }

  ensureList('users');
  ensureList('contacts');
  ensureList('admissions');
  ensureList('hostels');
  ensureList('rooms');
  ensureList('complaints');
  ensureList('checkins');

  final users = List<Map<String, dynamic>>.from(db['users'] as List);
  for (var i = 0; i < users.length; i++) {
    final u = Map<String, dynamic>.from(users[i]);
    if (u['role'] == null || u['role'].toString().trim().isEmpty) {
      u['role'] = 'student';
      users[i] = u;
      changed = true;
    }
  }

  final hasAdmin = users.any((u) => (u['role']?.toString() ?? '') == 'admin');
  if (!hasAdmin) {
    final adminEmail = (Platform.environment['ADMIN_EMAIL'] ?? _defaultAdminEmail)
        .trim()
        .toLowerCase();
    final adminPassword = Platform.environment['ADMIN_PASSWORD'] ?? _defaultAdminPassword;

    final existsEmail = users.any(
      (u) => (u['email']?.toString().toLowerCase() ?? '') == adminEmail,
    );
    if (!existsEmail) {
      users.add({
        'id': _id(),
        'name': 'Admin',
        'email': adminEmail,
        'passwordHash': _hashPassword(adminPassword),
        'gender': 'N/A',
        'age': 'N/A',
        'phone': 'N/A',
        'role': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
      });
      changed = true;
    }
  }

  db['users'] = users;

  if (changed) {
    await _writeDb(db);
  }
}

class _AuthException implements Exception {
  _AuthException(this.message, this.statusCode);
  final String message;
  final int statusCode;
}

String _requireAuthUserId(Request request) {
  final auth = request.headers[HttpHeaders.authorizationHeader];
  if (auth == null || !auth.startsWith('Bearer ')) {
    throw _AuthException('Missing bearer token', HttpStatus.unauthorized);
  }
  final token = auth.substring('Bearer '.length);
  final jwt = JWT.verify(token, SecretKey(_jwtSecret));
  final payload = jwt.payload as Map<String, dynamic>;
  final sub = payload['sub']?.toString();
  if (sub == null || sub.isEmpty) {
    throw _AuthException('Invalid token', HttpStatus.unauthorized);
  }
  return sub;
}

Future<void> _requireAdmin(Request request) async {
  final userId = _requireAuthUserId(request);
  final db = await _readDb();
  final users = List<Map<String, dynamic>>.from(db['users'] as List);
  final user = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u != null && u['id'] == userId,
        orElse: () => null,
      );
  if (user == null) {
    throw _AuthException('User not found', HttpStatus.unauthorized);
  }
  if ((user['role']?.toString() ?? 'student') != 'admin') {
    throw _AuthException('Admin access required', HttpStatus.forbidden);
  }
}

Middleware _errorMiddleware() {
  return (innerHandler) {
    return (request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (e) {
        return _error(e.message, HttpStatus.badRequest);
      } catch (_) {
        return _error('Internal server error', HttpStatus.internalServerError);
      }
    };
  };
}
