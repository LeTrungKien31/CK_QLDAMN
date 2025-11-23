// lib/services/api_service.dart
import '../models/activity.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../models/registration.dart';
import 'database_service.dart';

class ApiService {
  final DatabaseService _db = DatabaseService();

  // ============ ACTIVITY METHODS ============

  Future<List<Activity>> getActivities({String? status, String? search}) async {
    final data = await _db.getActivities(status: status, search: search);
    return data.map((item) => Activity.fromJson(item)).toList();
  }

  Future<Activity> getActivityById(int id) async {
    final data = await _db.getActivityById(id);
    if (data == null) throw Exception('Activity not found');
    return Activity.fromJson(data);
  }

  Future<Activity> createActivity(Map<String, dynamic> activityData) async {
    final data = await _db.createActivity(activityData);
    if (data == null) throw Exception('Failed to create activity');
    return Activity.fromJson(data);
  }

  Future<Activity> updateActivity(int id, Map<String, dynamic> activityData) async {
    final data = await _db.updateActivity(id, activityData);
    if (data == null) throw Exception('Failed to update activity');
    return Activity.fromJson(data);
  }

  Future<void> deleteActivity(int id) async {
    final success = await _db.deleteActivity(id);
    if (!success) throw Exception('Failed to delete activity');
  }

  // ============ REGISTRATION METHODS ============

  Future<List<dynamic>> getActivityRegistrations(int activityId) async {
    return await _db.getActivityRegistrations(activityId);
  }

  Future<void> registerActivity(int activityId) async {
    final data = await _db.registerActivity(activityId);
    if (data == null) throw Exception('Failed to register for activity');
  }

  Future<List<Registration>> getMyRegistrations() async {
    final data = await _db.getMyRegistrations();
    return data.map((item) => Registration.fromJson(item)).toList();
  }

  // ============ STUDENT METHODS ============

  Future<List<Student>> getStudents({String? search, String? className}) async {
    final data = await _db.getStudents(search: search, className: className);
    return data.map((item) => Student.fromJson(item)).toList();
  }

  Future<Student> getStudentById(int id) async {
    final data = await _db.getStudentById(id);
    if (data == null) throw Exception('Student not found');
    return Student.fromJson(data);
  }

  // ============ USER MANAGEMENT METHODS ============

  Future<List<User>> getUsers({String? search, String? role}) async {
    final data = await _db.getUsers(search: search, role: role);
    return data.map((item) => User.fromJson(item)).toList();
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    final data = await _db.createUser(userData);
    if (data == null) throw Exception('Failed to create user');
    
    // Nếu role là student, tạo thêm record trong bảng students
    if (userData['role'] == 'student' && userData['student_code'] != null) {
      await _db.createStudent({
        'user_id': data['id'],
        'student_code': userData['student_code'],
        'class_name': userData['class_name'],
        'major': userData['major'],
        'academic_year': userData['academic_year'],
        'date_of_birth': userData['date_of_birth'],
        'address': userData['address'],
      });
    }
    
    return User.fromJson(data);
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    final data = await _db.updateUser(id, userData);
    if (data == null) throw Exception('Failed to update user');
    return User.fromJson(data);
  }

  Future<void> deleteUser(int id) async {
    final success = await _db.deleteUser(id);
    if (!success) throw Exception('Failed to delete user');
  }

  // ============ ATTENDANCE METHODS ============

  Future<void> markAttendance(Map<String, dynamic> attendanceData) async {
    final data = await _db.markAttendance(attendanceData);
    if (data == null) throw Exception('Failed to mark attendance');
  }

  // ============ QR CODE METHODS ============

  Future<String> generateQRCode(int activityId, int validMinutes) async {
    return await _db.generateQRCode(activityId, validMinutes);
  }

  Future<Map<String, dynamic>> verifyQRCode(String qrData) async {
    return await _db.verifyQRCode(qrData);
  }

  // ============ STATISTICS METHODS ============

  Future<Map<String, dynamic>> getOverallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _db.getOverallStatistics(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ============ BACKUP METHODS ============

  Future<String> createBackup() async {
    return await _db.createBackup();
  }

  Future<List<dynamic>> getBackups() async {
    return await _db.getBackups();
  }

  Future<void> restoreBackup(String backupFile) async {
    await _db.restoreBackup(backupFile);
  }

  Future<void> deleteBackup(String backupFile) async {
    final success = await _db.deleteBackup(backupFile);
    if (!success) throw Exception('Failed to delete backup');
  }
}