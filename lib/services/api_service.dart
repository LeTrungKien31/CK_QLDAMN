// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/activity.dart';
import '../models/student.dart';
import '../models/registration.dart';
import '../models/attendance.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Thay đổi URL này theo backend của bạn
  static const String baseUrl = 'http://your-backend-url/api';
  String? _token;

  Future<void> init() async {
    await loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth APIs
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<User?> getCurrentUser() async {
    if (_token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  // User Management APIs
  Future<List<User>> getUsers({String? search, String? role}) async {
    var url = '$baseUrl/users';
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (role != null) params['role'] = role;
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<User> updateUser(int userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // Activity APIs
  Future<List<Activity>> getActivities({String? status, String? search}) async {
    var url = '$baseUrl/activities';
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load activities');
    }
  }

  Future<Activity> getActivityById(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities/$activityId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Activity.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load activity');
    }
  }

  Future<Activity> createActivity(Map<String, dynamic> activityData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: _headers,
      body: jsonEncode(activityData),
    );

    if (response.statusCode == 201) {
      return Activity.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create activity');
    }
  }

  Future<Activity> updateActivity(int activityId, Map<String, dynamic> activityData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/activities/$activityId'),
      headers: _headers,
      body: jsonEncode(activityData),
    );

    if (response.statusCode == 200) {
      return Activity.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update activity');
    }
  }

  Future<void> deleteActivity(int activityId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/activities/$activityId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete activity');
    }
  }

  // Registration APIs
  Future<List<dynamic>> getActivityRegistrations(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities/$activityId/registrations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load registrations');
    }
  }

  Future<void> registerActivity(int activityId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations'),
      headers: _headers,
      body: jsonEncode({'activity_id': activityId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register activity');
    }
  }

  Future<List<Registration>> getMyRegistrations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/registrations/my'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Registration.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load registrations');
    }
  }

  // Student APIs
  Future<List<Student>> getStudents({String? search, String? className}) async {
    var url = '$baseUrl/students';
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (className != null) params['class_name'] = className;
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  Future<Student> getStudentById(int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/$studentId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Student.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load student');
    }
  }

  // Attendance APIs
  Future<List<Attendance>> getAttendances({
    int? activityId,
    int? studentId,
    String? status,
  }) async {
    var url = '$baseUrl/attendances';
    final params = <String, String>{};
    if (activityId != null) params['activity_id'] = activityId.toString();
    if (studentId != null) params['student_id'] = studentId.toString();
    if (status != null) params['status'] = status;
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendances');
    }
  }

  Future<Attendance> markAttendance(Map<String, dynamic> attendanceData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendances'),
      headers: _headers,
      body: jsonEncode(attendanceData),
    );

    if (response.statusCode == 201) {
      return Attendance.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to mark attendance');
    }
  }

  Future<void> updateAttendance(int attendanceId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/attendances/$attendanceId'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update attendance');
    }
  }

  // QR Code APIs
  Future<String> generateQRCode(int activityId, int validMinutes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/qr/generate'),
      headers: _headers,
      body: jsonEncode({
        'activity_id': activityId,
        'valid_minutes': validMinutes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['qr_data'];
    } else {
      throw Exception('Failed to generate QR code');
    }
  }

  Future<Map<String, dynamic>> verifyQRCode(String qrData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/qr/verify'),
      headers: _headers,
      body: jsonEncode({'qr_data': qrData}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid QR code');
    }
  }

  // Report APIs
  Future<Map<String, dynamic>> getActivityReport(int activityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/activity/$activityId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load report');
    }
  }

  Future<Map<String, dynamic>> getStudentReport(int studentId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var url = '$baseUrl/reports/student/$studentId';
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load report');
    }
  }

  Future<Map<String, dynamic>> getOverallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var url = '$baseUrl/reports/statistics';
    final params = <String, String>{};
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  // Backup/Restore APIs
  Future<String> createBackup() async {
    final response = await http.post(
      Uri.parse('$baseUrl/backup/create'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['backup_file'];
    } else {
      throw Exception('Failed to create backup');
    }
  }

  Future<List<dynamic>> getBackups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/backup/list'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load backups');
    }
  }

  Future<void> restoreBackup(String backupFile) async {
    final response = await http.post(
      Uri.parse('$baseUrl/backup/restore'),
      headers: _headers,
      body: jsonEncode({'backup_file': backupFile}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to restore backup');
    }
  }

  Future<void> deleteBackup(String backupFile) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/backup/$backupFile'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete backup');
    }
  }
}