import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_service.dart';
import 'session_service.dart';

class FirebaseService {
  FirebaseService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String age,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final userData = {
        'id': uid,
        'name': name.trim(),
        'email': normalizedEmail,
        'gender': gender,
        'age': age,
        'phone': phone,
        'role': 'student',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _db.collection('users').doc(uid).set(userData);
      return _buildAuthResponse(userData);
    } on FirebaseAuthException catch (e) {
      throw ApiException(_authErrorMessage(e));
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final userData = await _fetchUserProfile(uid);
      return _buildAuthResponse(userData);
    } on FirebaseAuthException catch (e) {
      throw ApiException(_authErrorMessage(e));
    }
  }

  static Future<String> forgotPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return 'Password reset email sent. Check your inbox.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with that email.';
      }
      throw ApiException(_authErrorMessage(e));
    }
  }

  static Future<String> submitContact({
    required String name,
    required String phone,
    required String email,
    required String message,
  }) async {
    await _db.collection('contacts').add({
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'message': message.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    return 'Contact form submitted successfully';
  }

  static Future<String> submitAdmission({
    required String fullName,
    required String collegeId,
    required String email,
    required String phone,
    required String course,
    required String yearOfStudy,
    required String department,
    required String hostelType,
    required String roomType,
  }) async {
    await _db.collection('admissions').add({
      'fullName': fullName.trim(),
      'collegeId': collegeId.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'course': course.trim(),
      'yearOfStudy': yearOfStudy.trim(),
      'department': department.trim(),
      'hostelType': hostelType.trim(),
      'roomType': roomType.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    return 'Admission form submitted successfully';
  }

  static Future<void> submitComplaint({
    required String title,
    required String description,
  }) async {
    final uid = _requireAuthUid();
    await _db.collection('complaints').add({
      'userId': uid,
      'title': title.trim(),
      'description': description.trim(),
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> myComplaints() async {
    final uid = _requireAuthUid();
    final snapshot = await _db
        .collection('complaints')
        .where('userId', isEqualTo: uid)
        .get();
    final complaints = snapshot.docs.map(_docToMap).toList();
    complaints.sort(
      (a, b) => (b['createdAt']?.toString() ?? '')
          .compareTo(a['createdAt']?.toString() ?? ''),
    );
    return complaints;
  }

  static Future<List<Map<String, dynamic>>> myCheckins() async {
    final uid = _requireAuthUid();
    final checkinsSnapshot =
        await _db.collection('checkins').where('userId', isEqualTo: uid).get();
    final roomsSnapshot = await _db.collection('rooms').get();
    final roomsById = {
      for (final doc in roomsSnapshot.docs) doc.id: _docToMap(doc),
    };

    final checkins = checkinsSnapshot.docs.map((doc) {
      final checkin = _docToMap(doc);
      final room = roomsById[checkin['roomId']?.toString() ?? ''];
      if (room != null) {
        checkin['room'] = room;
      }
      return checkin;
    }).toList();

    checkins.sort(
      (a, b) => (b['checkInAt']?.toString() ?? '')
          .compareTo(a['checkInAt']?.toString() ?? ''),
    );
    return checkins;
  }

  static Future<Map<String, dynamic>> myRoom() async {
    final uid = _requireAuthUid();
    final checkinsSnapshot =
        await _db.collection('checkins').where('userId', isEqualTo: uid).get();

    Map<String, dynamic>? activeCheckin;
    for (final doc in checkinsSnapshot.docs) {
      final checkin = _docToMap(doc);
      if ((checkin['checkOutAt']?.toString() ?? '').isEmpty) {
        activeCheckin = checkin;
        break;
      }
    }

    if (activeCheckin == null) {
      return {'activeCheckin': null, 'room': null};
    }

    final roomId = activeCheckin['roomId']?.toString() ?? '';
    final roomDoc = await _db.collection('rooms').doc(roomId).get();
    return {
      'activeCheckin': activeCheckin,
      'room': roomDoc.exists ? _docToMap(roomDoc) : null,
    };
  }

  static Future<Map<String, dynamic>> adminDashboard() async {
    await _requireAdmin();
    final usersSnapshot = await _db.collection('users').get();
    final roomsSnapshot = await _db.collection('rooms').get();
    final complaintsSnapshot = await _db.collection('complaints').get();
    final checkinsSnapshot = await _db.collection('checkins').get();

    final users = usersSnapshot.docs.map(_docToMap);
    final studentsCount =
        users.where((u) => (u['role']?.toString() ?? 'student') == 'student').length;
    final adminsCount =
        users.where((u) => (u['role']?.toString() ?? 'student') == 'admin').length;
    final activeCheckins = checkinsSnapshot.docs.map(_docToMap).where(
          (c) => (c['checkOutAt']?.toString() ?? '').isEmpty,
        ).length;
    final openComplaints = complaintsSnapshot.docs.map(_docToMap).where((c) {
      final status = (c['status']?.toString() ?? 'open').toLowerCase();
      return status != 'resolved' && status != 'closed';
    }).length;

    return {
      'students': studentsCount,
      'admins': adminsCount,
      'rooms': roomsSnapshot.docs.length,
      'activeCheckins': activeCheckins,
      'openComplaints': openComplaints,
    };
  }

  static Future<List<Map<String, dynamic>>> adminListUsers() async {
    await _requireAdmin();
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => _safeUser(_docToMap(doc))).toList();
  }

  static Future<Map<String, dynamic>> adminUpdateUser(
    String id, {
    String? role,
    String? name,
    String? phone,
  }) async {
    await _requireAdmin();
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (updates.isEmpty) {
      throw ApiException('No fields to update');
    }

    final docRef = _db.collection('users').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw ApiException('User not found');
    }
    await docRef.update(updates);
    final updated = _docToMap(await docRef.get());
    return _safeUser(updated);
  }

  static Future<List<Map<String, dynamic>>> adminListRooms() async {
    await _requireAdmin();
    final snapshot = await _db.collection('rooms').get();
    return snapshot.docs.map(_docToMap).toList();
  }

  static Future<void> adminCreateRoom({
    required String building,
    required String roomNo,
    required String type,
    required int capacity,
    int floor = 0,
    String status = 'available',
  }) async {
    await _requireAdmin();
    await _db.collection('rooms').add({
      'building': building.trim(),
      'floor': floor,
      'roomNo': roomNo.trim(),
      'capacity': capacity,
      'occupiedCount': 0,
      'type': type.trim(),
      'status': status.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> adminUpdateRoom(
    String id, {
    String? building,
    String? roomNo,
    String? type,
    int? capacity,
    int? floor,
    String? status,
  }) async {
    await _requireAdmin();
    final updates = <String, dynamic>{};
    if (building != null) updates['building'] = building;
    if (roomNo != null) updates['roomNo'] = roomNo;
    if (type != null) updates['type'] = type;
    if (capacity != null) updates['capacity'] = capacity;
    if (floor != null) updates['floor'] = floor;
    if (status != null) updates['status'] = status;
    if (updates.isEmpty) {
      throw ApiException('No fields to update');
    }

    final docRef = _db.collection('rooms').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw ApiException('Room not found');
    }
    await docRef.update(updates);
  }

  static Future<List<Map<String, dynamic>>> adminListComplaints() async {
    await _requireAdmin();
    final complaintsSnapshot = await _db.collection('complaints').get();
    final usersSnapshot = await _db.collection('users').get();
    final usersById = {
      for (final doc in usersSnapshot.docs)
        doc.id: _safeUser(_docToMap(doc)),
    };

    return complaintsSnapshot.docs.map((doc) {
      final complaint = _docToMap(doc);
      final user = usersById[complaint['userId']?.toString() ?? ''];
      if (user != null) {
        complaint['user'] = user;
      }
      return complaint;
    }).toList();
  }

  static Future<void> adminUpdateComplaintStatus(String id, String status) async {
    await _requireAdmin();
    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus.isEmpty) {
      throw ApiException('Missing field: status');
    }

    final docRef = _db.collection('complaints').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw ApiException('Complaint not found');
    }

    final updates = <String, dynamic>{'status': normalizedStatus};
    if (normalizedStatus == 'resolved' || normalizedStatus == 'closed') {
      updates['resolvedAt'] = DateTime.now().toIso8601String();
    }
    await docRef.update(updates);
  }

  static Future<List<Map<String, dynamic>>> adminListCheckins() async {
    await _requireAdmin();
    final checkinsSnapshot = await _db.collection('checkins').get();
    final usersSnapshot = await _db.collection('users').get();
    final roomsSnapshot = await _db.collection('rooms').get();

    final usersById = {
      for (final doc in usersSnapshot.docs)
        doc.id: _safeUser(_docToMap(doc)),
    };
    final roomsById = {
      for (final doc in roomsSnapshot.docs) doc.id: _docToMap(doc),
    };

    return checkinsSnapshot.docs.map((doc) {
      final checkin = _docToMap(doc);
      final user = usersById[checkin['userId']?.toString() ?? ''];
      final room = roomsById[checkin['roomId']?.toString() ?? ''];
      if (user != null) checkin['user'] = user;
      if (room != null) checkin['room'] = room;
      return checkin;
    }).toList();
  }

  static Future<void> adminCheckIn({
    required String userId,
    required String roomId,
  }) async {
    await _requireAdmin();
    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw ApiException('User not found');
    }

    final activeCheckins = await _db
        .collection('checkins')
        .where('userId', isEqualTo: userId)
        .get();
    final alreadyActive = activeCheckins.docs.any(
      (doc) => (_docToMap(doc)['checkOutAt']?.toString() ?? '').isEmpty,
    );
    if (alreadyActive) {
      throw ApiException('User already checked-in');
    }

    final roomRef = _db.collection('rooms').doc(roomId);
    final checkinRef = _db.collection('checkins').doc();

    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) {
        throw ApiException('Room not found');
      }

      final room = _docToMap(roomSnap);
      final capacity = int.tryParse(room['capacity']?.toString() ?? '') ?? 1;
      final occupied =
          int.tryParse(room['occupiedCount']?.toString() ?? '') ?? 0;
      if (occupied >= capacity) {
        throw ApiException('Room is full');
      }

      transaction.set(checkinRef, {
        'userId': userId,
        'roomId': roomId,
        'checkInAt': DateTime.now().toIso8601String(),
        'checkOutAt': '',
      });
      transaction.update(roomRef, {'occupiedCount': occupied + 1});
    });
  }

  static Future<void> adminCheckOut({required String checkinId}) async {
    await _requireAdmin();
    final checkinRef = _db.collection('checkins').doc(checkinId);

    await _db.runTransaction((transaction) async {
      final checkinSnap = await transaction.get(checkinRef);
      if (!checkinSnap.exists) {
        throw ApiException('Check-in not found');
      }

      final checkin = _docToMap(checkinSnap);
      if ((checkin['checkOutAt']?.toString() ?? '').isNotEmpty) {
        throw ApiException('Already checked-out');
      }

      final roomId = checkin['roomId']?.toString() ?? '';
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomSnap = await transaction.get(roomRef);

      transaction.update(checkinRef, {
        'checkOutAt': DateTime.now().toIso8601String(),
      });

      if (roomSnap.exists) {
        final room = _docToMap(roomSnap);
        final occupied =
            int.tryParse(room['occupiedCount']?.toString() ?? '') ?? 0;
        transaction.update(roomRef, {
          'occupiedCount': occupied > 0 ? occupied - 1 : 0,
        });
      }
    });
  }

  static Future<void> restoreSessionIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _fetchUserProfile(user.uid);
      await ApiService.saveSession({
        'token': await user.getIdToken() ?? '',
        'user': _safeUser(profile),
      });
    } catch (_) {
      await SessionService.clear();
    }
  }

  static Future<Map<String, dynamic>> _buildAuthResponse(
    Map<String, dynamic> userData,
  ) async {
    final token = await _auth.currentUser?.getIdToken() ?? '';
    final authData = {
      'message': 'Login successful',
      'token': token,
      'user': _safeUser(userData),
    };
    await ApiService.saveSession(authData);
    return authData;
  }

  static Future<Map<String, dynamic>> _fetchUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw ApiException('User profile not found. Contact the hostel office.');
    }
    return _docToMap(doc);
  }

  static String _requireAuthUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw ApiException('Please sign in again');
    }
    return uid;
  }

  static Future<void> _requireAdmin() async {
    final uid = _requireAuthUid();
    final profile = await _fetchUserProfile(uid);
    if ((profile['role']?.toString() ?? 'student') != 'admin') {
      throw ApiException('Admin access required');
    }
  }

  static Map<String, dynamic> _docToMap(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    data['id'] = doc.id;
    return data;
  }

  static Map<String, dynamic> _safeUser(Map<String, dynamic> user) {
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

  static String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'User already exists with this email';
      case 'invalid-email':
        return 'Enter a valid email';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters)';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
