import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/backend_config.dart';
import 'firebase_service.dart';

class ApiService {
  ApiService._();

  static String get baseUrl {
    const explicitBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (explicitBaseUrl.isNotEmpty) {
      return explicitBaseUrl;
    }

    const apiPort = int.fromEnvironment('API_PORT', defaultValue: 8081);
    if (kIsWeb) {
      // On Windows, browsers may resolve `localhost` to IPv6 (::1) first, while the
      // demo backend binds to IPv4 (127.0.0.1). Use IPv4 loopback to avoid "Failed to fetch".
      return 'http://127.0.0.1:$apiPort/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$apiPort/api';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:$apiPort/api';
    }
    return 'http://localhost:$apiPort/api';
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String age,
    required String phone,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.register(
        name: name,
        email: email,
        password: password,
        gender: gender,
        age: age,
        phone: phone,
      );
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'gender': gender,
        'age': age,
        'phone': phone,
      }),
    );
    return _handleAuthResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.login(email: email, password: password);
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return _handleAuthResponse(response);
    } on http.ClientException catch (_) {
      throw ApiException('Network error while contacting backend. Ensure it is running on $baseUrl');
    } catch (_) {
      throw ApiException('Cannot reach backend. Start it with: `dart run backend/bin/server.dart`');
    }
  }

  static Future<String> forgotPassword(String email) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.forgotPassword(email);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Could not process request');
    }
    return data['message']?.toString() ?? 'Request submitted';
  }

  static Future<String> submitContact({
    required String name,
    required String phone,
    required String email,
    required String message,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.submitContact(
        name: name,
        phone: phone,
        email: email,
        message: message,
      );
    }
    final response = await http.post(
      Uri.parse('$baseUrl/contact'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'message': message,
      }),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Could not submit contact form');
    }
    return data['message']?.toString() ?? 'Submitted';
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
    if (BackendConfig.useFirebase) {
      return FirebaseService.submitAdmission(
        fullName: fullName,
        collegeId: collegeId,
        email: email,
        phone: phone,
        course: course,
        yearOfStudy: yearOfStudy,
        department: department,
        hostelType: hostelType,
        roomType: roomType,
      );
    }
    final response = await http.post(
      Uri.parse('$baseUrl/admissions'),
      headers: _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'collegeId': collegeId,
        'email': email,
        'phone': phone,
        'course': course,
        'yearOfStudy': yearOfStudy,
        'department': department,
        'hostelType': hostelType,
        'roomType': roomType,
      }),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Could not submit admission form');
    }
    return data['message']?.toString() ?? 'Submitted';
  }

  static Future<void> saveSession(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', authData['token']?.toString() ?? '');
    await prefs.setString('auth_user', jsonEncode(authData['user'] ?? const {}));
  }

  // -------- Student APIs (require JWT) --------
  static Future<void> submitComplaint({
    required String title,
    required String description,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.submitComplaint(title: title, description: description);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: await _authHeaders(),
      body: jsonEncode({'title': title, 'description': description}),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }

  static Future<List<Map<String, dynamic>>> myComplaints() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.myComplaints();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/my/complaints'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final complaints = (data['complaints'] as List?) ?? const [];
    return complaints.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> myCheckins() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.myCheckins();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/my/checkins'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final checkins = (data['checkins'] as List?) ?? const [];
    return checkins.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  static Future<Map<String, dynamic>> myRoom() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.myRoom();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/my/room'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    return data;
  }

  static Map<String, String> _headers() => const {
        'Content-Type': 'application/json',
      };

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final headers = <String, String>{..._headers()};
    if (token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    await saveSession(data);
    return data;
  }
  
  // -------- Admin APIs (require admin JWT) --------
  static Future<Map<String, dynamic>> adminDashboard() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminDashboard();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    return Map<String, dynamic>.from(data['counts'] as Map);
  }

  static Future<List<Map<String, dynamic>>> adminListUsers() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminListUsers();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final users = (data['users'] as List?) ?? const [];
    return users.map((u) => Map<String, dynamic>.from(u as Map)).toList();
  }

  static Future<Map<String, dynamic>> adminUpdateUser(
    String id, {
    String? role,
    String? name,
    String? phone,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminUpdateUser(id, role: role, name: name, phone: phone);
    }
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/users/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  static Future<List<Map<String, dynamic>>> adminListRooms() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminListRooms();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/admin/rooms'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final rooms = (data['rooms'] as List?) ?? const [];
    return rooms.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  }

  static Future<void> adminCreateRoom({
    required String building,
    required String roomNo,
    required String type,
    required int capacity,
    int floor = 0,
    String status = 'available',
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminCreateRoom(
        building: building,
        roomNo: roomNo,
        type: type,
        capacity: capacity,
        floor: floor,
        status: status,
      );
    }
    final response = await http.post(
      Uri.parse('$baseUrl/admin/rooms'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'building': building,
        'roomNo': roomNo,
        'type': type,
        'capacity': capacity,
        'floor': floor,
        'status': status,
      }),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
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
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminUpdateRoom(
        id,
        building: building,
        roomNo: roomNo,
        type: type,
        capacity: capacity,
        floor: floor,
        status: status,
      );
    }
    final body = <String, dynamic>{};
    if (building != null) body['building'] = building;
    if (roomNo != null) body['roomNo'] = roomNo;
    if (type != null) body['type'] = type;
    if (capacity != null) body['capacity'] = capacity;
    if (floor != null) body['floor'] = floor;
    if (status != null) body['status'] = status;

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/rooms/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }

  static Future<List<Map<String, dynamic>>> adminListComplaints() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminListComplaints();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/admin/complaints'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final complaints = (data['complaints'] as List?) ?? const [];
    return complaints.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  static Future<void> adminUpdateComplaintStatus(String id, String status) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminUpdateComplaintStatus(id, status);
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/admin/complaints/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }

  static Future<List<Map<String, dynamic>>> adminListCheckins() async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminListCheckins();
    }
    final response = await http.get(
      Uri.parse('$baseUrl/admin/checkins'),
      headers: await _authHeaders(),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
    final checkins = (data['checkins'] as List?) ?? const [];
    return checkins.map((c) => Map<String, dynamic>.from(c as Map)).toList();
  }

  static Future<void> adminCheckIn({
    required String userId,
    required String roomId,
  }) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminCheckIn(userId: userId, roomId: roomId);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/admin/checkin'),
      headers: await _authHeaders(),
      body: jsonEncode({'userId': userId, 'roomId': roomId}),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }

  static Future<void> adminCheckOut({required String checkinId}) async {
    if (BackendConfig.useFirebase) {
      return FirebaseService.adminCheckOut(checkinId: checkinId);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/admin/checkout'),
      headers: await _authHeaders(),
      body: jsonEncode({'checkinId': checkinId}),
    );
    final data = _decode(response);
    if (response.statusCode >= 400) {
      throw ApiException(data['message']?.toString() ?? 'Request failed');
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
