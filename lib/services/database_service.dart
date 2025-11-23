// lib/services/database_service.dart
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Connection? _connection;
  int? _currentUserId;

  // Cấu hình kết nối PostgreSQL
  static const String host = 'localhost'; // Thay đổi theo server của bạn
  static const int port = 5432;
  static const String database = 'student_management'; // Tên database
  static const String username = 'postgres'; // Username
  static const String password = '123'; // Password

  Future<void> init() async {
    await connect();
    await _loadCurrentUser();
  }

  Future<void> connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ),
      );
      print('Connected to PostgreSQL database');
    } catch (e) {
      print('Failed to connect to database: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('current_user_id');
  }

  Future<void> _saveCurrentUser(int userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', userId);
  }

  Future<void> clearCurrentUser() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  int? get currentUserId => _currentUserId;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============ AUTH METHODS ============

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      
      final result = await _connection!.execute(
        Sql.named('''
          SELECT u.*, 
                 CASE WHEN u.role = 'student' THEN s.id ELSE NULL END as student_id
          FROM users u
          LEFT JOIN students s ON u.id = s.user_id
          WHERE u.username = @username 
            AND u.password_hash = @password 
            AND u.is_active = true
        '''),
        parameters: {
          'username': username,
          'password': hashedPassword,
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      await _saveCurrentUser(row[0] as int);

      return {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'full_name': row[3],
        'role': row[4],
        'phone': row[5],
        'avatar_url': row[6],
        'is_active': row[7],
        'created_at': row[8],
        'student_id': row[9],
      };
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUserId == null) return null;

    try {
      final result = await _connection!.execute(
        Sql.named('''
          SELECT u.*, 
                 CASE WHEN u.role = 'student' THEN s.id ELSE NULL END as student_id
          FROM users u
          LEFT JOIN students s ON u.id = s.user_id
          WHERE u.id = @userId AND u.is_active = true
        '''),
        parameters: {'userId': _currentUserId},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'full_name': row[3],
        'role': row[4],
        'phone': row[5],
        'avatar_url': row[6],
        'is_active': row[7],
        'created_at': row[8],
        'student_id': row[9],
      };
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUserId == null) return false;

    try {
      final oldHashed = _hashPassword(oldPassword);
      final newHashed = _hashPassword(newPassword);

      final result = await _connection!.execute(
        Sql.named('''
          UPDATE users 
          SET password_hash = @newPassword
          WHERE id = @userId AND password_hash = @oldPassword
        '''),
        parameters: {
          'userId': _currentUserId,
          'oldPassword': oldHashed,
          'newPassword': newHashed,
        },
      );

      return result.affectedRows > 0;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  // ============ USER MANAGEMENT ============

  Future<List<Map<String, dynamic>>> getUsers({String? search, String? role}) async {
    try {
      String query = 'SELECT * FROM users WHERE 1=1';
      Map<String, dynamic> parameters = {};

      if (search != null && search.isNotEmpty) {
        query += ''' AND (
          username ILIKE @search OR 
          email ILIKE @search OR 
          full_name ILIKE @search
        )''';
        parameters['search'] = '%$search%';
      }

      if (role != null && role.isNotEmpty) {
        query += ' AND role = @role';
        parameters['role'] = role;
      }

      query += ' ORDER BY created_at DESC';

      final result = await _connection!.execute(
        Sql.named(query),
        parameters: parameters,
      );

      return result.map((row) => {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'full_name': row[3],
        'role': row[4],
        'phone': row[5],
        'avatar_url': row[6],
        'is_active': row[7],
        'created_at': row[8],
      }).toList();
    } catch (e) {
      print('Get users error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> userData) async {
    try {
      final hashedPassword = _hashPassword(userData['password']);

      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO users (username, email, password_hash, full_name, role, phone, is_active)
          VALUES (@username, @email, @password, @fullName, @role, @phone, true)
          RETURNING *
        '''),
        parameters: {
          'username': userData['username'],
          'email': userData['email'],
          'password': hashedPassword,
          'fullName': userData['full_name'],
          'role': userData['role'],
          'phone': userData['phone'],
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'full_name': row[3],
        'role': row[4],
        'phone': row[5],
        'avatar_url': row[6],
        'is_active': row[7],
        'created_at': row[8],
      };
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          UPDATE users 
          SET email = @email, 
              full_name = @fullName, 
              role = @role, 
              phone = @phone
          WHERE id = @userId
          RETURNING *
        '''),
        parameters: {
          'userId': userId,
          'email': userData['email'],
          'fullName': userData['full_name'],
          'role': userData['role'],
          'phone': userData['phone'],
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'full_name': row[3],
        'role': row[4],
        'phone': row[5],
        'avatar_url': row[6],
        'is_active': row[7],
        'created_at': row[8],
      };
    } catch (e) {
      print('Update user error: $e');
      return null;
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final result = await _connection!.execute(
        Sql.named('DELETE FROM users WHERE id = @userId'),
        parameters: {'userId': userId},
      );
      return result.affectedRows > 0;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }

  // ============ ACTIVITY METHODS ============

  Future<List<Map<String, dynamic>>> getActivities({String? status, String? search}) async {
    try {
      String query = '''
        SELECT a.*, u.full_name as organizer_name,
               (SELECT COUNT(*) FROM registrations WHERE activity_id = a.id) as registered_count,
               (SELECT COUNT(*) FROM attendances att 
                JOIN registrations r ON att.registration_id = r.id 
                WHERE r.activity_id = a.id) as attended_count
        FROM activities a
        LEFT JOIN users u ON a.organizer_id = u.id
        WHERE 1=1
      ''';
      Map<String, dynamic> parameters = {};

      if (status != null && status.isNotEmpty) {
        query += ' AND a.status = @status';
        parameters['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        query += ' AND (a.title ILIKE @search OR a.description ILIKE @search)';
        parameters['search'] = '%$search%';
      }

      query += ' ORDER BY a.start_time DESC';

      final result = await _connection!.execute(
        Sql.named(query),
        parameters: parameters,
      );

      return result.map((row) => {
        'id': row[0],
        'title': row[1],
        'description': row[2],
        'location': row[3],
        'start_time': row[4],
        'end_time': row[5],
        'registration_deadline': row[6],
        'max_participants': row[7],
        'activity_type': row[8],
        'organizer_id': row[9],
        'status': row[10],
        'image_url': row[11],
        'created_at': row[12],
        'organizer_name': row[13],
        'registered_count': row[14],
        'attended_count': row[15],
      }).toList();
    } catch (e) {
      print('Get activities error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getActivityById(int activityId) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          SELECT a.*, u.full_name as organizer_name,
                 (SELECT COUNT(*) FROM registrations WHERE activity_id = a.id) as registered_count,
                 (SELECT COUNT(*) FROM attendances att 
                  JOIN registrations r ON att.registration_id = r.id 
                  WHERE r.activity_id = a.id) as attended_count
          FROM activities a
          LEFT JOIN users u ON a.organizer_id = u.id
          WHERE a.id = @activityId
        '''),
        parameters: {'activityId': activityId},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'title': row[1],
        'description': row[2],
        'location': row[3],
        'start_time': row[4],
        'end_time': row[5],
        'registration_deadline': row[6],
        'max_participants': row[7],
        'activity_type': row[8],
        'organizer_id': row[9],
        'status': row[10],
        'image_url': row[11],
        'created_at': row[12],
        'organizer_name': row[13],
        'registered_count': row[14],
        'attended_count': row[15],
      };
    } catch (e) {
      print('Get activity error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createActivity(Map<String, dynamic> activityData) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO activities (
            title, description, location, start_time, end_time, 
            registration_deadline, max_participants, activity_type, 
            organizer_id, status
          )
          VALUES (
            @title, @description, @location, @startTime, @endTime,
            @registrationDeadline, @maxParticipants, @activityType,
            @organizerId, @status
          )
          RETURNING *
        '''),
        parameters: {
          'title': activityData['title'],
          'description': activityData['description'],
          'location': activityData['location'],
          'startTime': activityData['start_time'],
          'endTime': activityData['end_time'],
          'registrationDeadline': activityData['registration_deadline'],
          'maxParticipants': activityData['max_participants'],
          'activityType': activityData['activity_type'],
          'organizerId': _currentUserId,
          'status': activityData['status'] ?? 'upcoming',
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'title': row[1],
        'description': row[2],
        'location': row[3],
        'start_time': row[4],
        'end_time': row[5],
        'registration_deadline': row[6],
        'max_participants': row[7],
        'activity_type': row[8],
        'organizer_id': row[9],
        'status': row[10],
        'image_url': row[11],
        'created_at': row[12],
      };
    } catch (e) {
      print('Create activity error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateActivity(int activityId, Map<String, dynamic> activityData) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          UPDATE activities 
          SET title = @title,
              description = @description,
              location = @location,
              start_time = @startTime,
              end_time = @endTime,
              registration_deadline = @registrationDeadline,
              max_participants = @maxParticipants,
              activity_type = @activityType,
              status = @status
          WHERE id = @activityId
          RETURNING *
        '''),
        parameters: {
          'activityId': activityId,
          'title': activityData['title'],
          'description': activityData['description'],
          'location': activityData['location'],
          'startTime': activityData['start_time'],
          'endTime': activityData['end_time'],
          'registrationDeadline': activityData['registration_deadline'],
          'maxParticipants': activityData['max_participants'],
          'activityType': activityData['activity_type'],
          'status': activityData['status'],
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'title': row[1],
        'description': row[2],
        'location': row[3],
        'start_time': row[4],
        'end_time': row[5],
        'registration_deadline': row[6],
        'max_participants': row[7],
        'activity_type': row[8],
        'organizer_id': row[9],
        'status': row[10],
        'image_url': row[11],
        'created_at': row[12],
      };
    } catch (e) {
      print('Update activity error: $e');
      return null;
    }
  }

  Future<bool> deleteActivity(int activityId) async {
    try {
      final result = await _connection!.execute(
        Sql.named('DELETE FROM activities WHERE id = @activityId'),
        parameters: {'activityId': activityId},
      );
      return result.affectedRows > 0;
    } catch (e) {
      print('Delete activity error: $e');
      return false;
    }
  }

  // ============ STUDENT METHODS ============

  Future<List<Map<String, dynamic>>> getStudents({String? search, String? className}) async {
    try {
      String query = '''
        SELECT s.*, u.username, u.email, u.full_name, u.phone, u.avatar_url
        FROM students s
        JOIN users u ON s.user_id = u.id
        WHERE u.is_active = true
      ''';
      Map<String, dynamic> parameters = {};

      if (search != null && search.isNotEmpty) {
        query += ''' AND (
          s.student_code ILIKE @search OR 
          u.full_name ILIKE @search OR
          u.email ILIKE @search
        )''';
        parameters['search'] = '%$search%';
      }

      if (className != null && className.isNotEmpty) {
        query += ' AND s.class_name = @className';
        parameters['className'] = className;
      }

      query += ' ORDER BY s.student_code';

      final result = await _connection!.execute(
        Sql.named(query),
        parameters: parameters,
      );

      return result.map((row) => {
        'id': row[0],
        'user_id': row[1],
        'student_code': row[2],
        'class_name': row[3],
        'major': row[4],
        'academic_year': row[5],
        'date_of_birth': row[6],
        'address': row[7],
        'user': {
          'username': row[8],
          'email': row[9],
          'full_name': row[10],
          'phone': row[11],
          'avatar_url': row[12],
        },
      }).toList();
    } catch (e) {
      print('Get students error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getStudentById(int studentId) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          SELECT s.*, u.username, u.email, u.full_name, u.phone, u.avatar_url
          FROM students s
          JOIN users u ON s.user_id = u.id
          WHERE s.id = @studentId
        '''),
        parameters: {'studentId': studentId},
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'user_id': row[1],
        'student_code': row[2],
        'class_name': row[3],
        'major': row[4],
        'academic_year': row[5],
        'date_of_birth': row[6],
        'address': row[7],
        'user': {
          'username': row[8],
          'email': row[9],
          'full_name': row[10],
          'phone': row[11],
          'avatar_url': row[12],
        },
      };
    } catch (e) {
      print('Get student error: $e');
      return null;
    }
  }

  // ============ REGISTRATION METHODS ============

  Future<List<Map<String, dynamic>>> getActivityRegistrations(int activityId) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          SELECT r.*, s.student_code, u.full_name
          FROM registrations r
          JOIN students s ON r.student_id = s.id
          JOIN users u ON s.user_id = u.id
          WHERE r.activity_id = @activityId
          ORDER BY r.registration_time DESC
        '''),
        parameters: {'activityId': activityId},
      );

      return result.map((row) => {
        'id': row[0],
        'activity_id': row[1],
        'student_id': row[2],
        'registration_time': row[3],
        'status': row[4],
        'notes': row[5],
        'student': {
          'student_code': row[6],
          'user': {
            'full_name': row[7],
          },
        },
      }).toList();
    } catch (e) {
      print('Get registrations error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> registerActivity(int activityId) async {
    try {
      // Get student_id from current user
      final studentResult = await _connection!.execute(
        Sql.named('SELECT id FROM students WHERE user_id = @userId'),
        parameters: {'userId': _currentUserId},
      );

      if (studentResult.isEmpty) return null;
      final studentId = studentResult.first[0] as int;

      // Check if already registered
      final checkResult = await _connection!.execute(
        Sql.named('''
          SELECT id FROM registrations 
          WHERE activity_id = @activityId AND student_id = @studentId
        '''),
        parameters: {
          'activityId': activityId,
          'studentId': studentId,
        },
      );

      if (checkResult.isNotEmpty) {
        throw Exception('Already registered');
      }

      // Register
      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO registrations (activity_id, student_id, status)
          VALUES (@activityId, @studentId, 'registered')
          RETURNING *
        '''),
        parameters: {
          'activityId': activityId,
          'studentId': studentId,
        },
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'id': row[0],
        'activity_id': row[1],
        'student_id': row[2],
        'registration_time': row[3],
        'status': row[4],
        'notes': row[5],
      };
    } catch (e) {
      print('Register activity error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyRegistrations() async {
    try {
      // Get student_id from current user
      final studentResult = await _connection!.execute(
        Sql.named('SELECT id FROM students WHERE user_id = @userId'),
        parameters: {'userId': _currentUserId},
      );

      if (studentResult.isEmpty) return [];
      final studentId = studentResult.first[0] as int;

      final result = await _connection!.execute(
        Sql.named('''
          SELECT r.*, a.title, a.description, a.location, a.start_time, 
                 a.end_time, a.status as activity_status
          FROM registrations r
          JOIN activities a ON r.activity_id = a.id
          WHERE r.student_id = @studentId
          ORDER BY a.start_time DESC
        '''),
        parameters: {'studentId': studentId},
      );

      return result.map((row) => {
        'id': row[0],
        'activity_id': row[1],
        'student_id': row[2],
        'registration_time': row[3],
        'status': row[4],
        'notes': row[5],
        'activity': {
          'title': row[6],
          'description': row[7],
          'location': row[8],
          'start_time': row[9],
          'end_time': row[10],
          'status': row[11],
        },
      }).toList();
    } catch (e) {
      print('Get my registrations error: $e');
      return [];
    }
  }

  // ============ ATTENDANCE METHODS ============

  Future<Map<String, dynamic>?> markAttendance(Map<String, dynamic> attendanceData) async {
    try {
      final result = await _connection!.execute(
        Sql.named('''
          INSERT INTO attendances (
            registration_id, activity_id, student_id, 
            attendance_method, status, recorded_by, notes
          )
          VALUES (
            @registrationId, @activityId, @studentId,
            @attendanceMethod, @status, @recordedBy, @notes
          )
          RETURNING *
        '''),
        parameters: {
          'registrationId': attendanceData['registration_id'],
          'activityId': attendanceData['activity_id'],
          'studentId': attendanceData['student_id'],
          'attendanceMethod': attendanceData['attendance_method'],
          'status': attendanceData['status'],
          'recordedBy': _currentUserId,
          'notes': attendanceData['notes'],
        },
      );

      if (result.isEmpty) return null;

      // Update registration status
      await _connection!.execute(
        Sql.named('''
          UPDATE registrations 
          SET status = 'attended' 
          WHERE id = @registrationId
        '''),
        parameters: {'registrationId': attendanceData['registration_id']},
      );

      final row = result.first;
      return {
        'id': row[0],
        'registration_id': row[1],
        'activity_id': row[2],
        'student_id': row[3],
        'attendance_time': row[4],
        'attendance_method': row[5],
        'status': row[6],
        'recorded_by': row[7],
        'notes': row[8],
      };
    } catch (e) {
      print('Mark attendance error: $e');
      return null;
    }
  }

  // ============ QR CODE METHODS ============

  Future<String> generateQRCode(int activityId, int validMinutes) async {
    try {
      final expiresAt = DateTime.now().add(Duration(minutes: validMinutes));
      
      final qrData = jsonEncode({
        'activity_id': activityId,
        'expires_at': expiresAt.toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
      });

      final encoded = base64Encode(utf8.encode(qrData));
      return encoded;
    } catch (e) {
      print('Generate QR code error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyQRCode(String qrData) async {
    try {
      final decoded = utf8.decode(base64Decode(qrData));
      final data = jsonDecode(decoded);
      
      final expiresAt = DateTime.parse(data['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        return {'valid': false, 'message': 'QR code đã hết hạn'};
      }

      final activityId = data['activity_id'];

      // Get student_id from current user
      final studentResult = await _connection!.execute(
        Sql.named('SELECT id FROM students WHERE user_id = @userId'),
        parameters: {'userId': _currentUserId},
      );

      if (studentResult.isEmpty) {
        return {'valid': false, 'message': 'Không tìm thấy thông tin sinh viên'};
      }
      final studentId = studentResult.first[0] as int;

      // Check registration
      final regResult = await _connection!.execute(
        Sql.named('''
          SELECT id FROM registrations 
          WHERE activity_id = @activityId AND student_id = @studentId
        '''),
        parameters: {
          'activityId': activityId,
          'studentId': studentId,
        },
      );

      if (regResult.isEmpty) {
        return {'valid': false, 'message': 'Bạn chưa đăng ký hoạt động này'};
      }

      final registrationId = regResult.first[0] as int;

      // Check if already attended
      final attendResult = await _connection!.execute(
        Sql.named('''
          SELECT id FROM attendances 
          WHERE registration_id = @registrationId
        '''),
        parameters: {'registrationId': registrationId},
      );

      if (attendResult.isNotEmpty) {
        return {'valid': false, 'message': 'Bạn đã điểm danh rồi'};
      }

      return {
        'valid': true,
        'registration_id': registrationId,
        'activity_id': activityId,
        'student_id': studentId,
      };
    } catch (e) {
      print('Verify QR code error: $e');
      return {'valid': false, 'message': 'QR code không hợp lệ'};
    }
  }

  // ============ STATISTICS METHODS ============

  Future<Map<String, dynamic>> getOverallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String dateFilter = '';
      Map<String, dynamic> parameters = {};

      if (startDate != null && endDate != null) {
        dateFilter = ' AND a.created_at BETWEEN @startDate AND @endDate';
        parameters['startDate'] = startDate;
        parameters['endDate'] = endDate;
      }

      // Total activities
      final activitiesResult = await _connection!.execute(
        Sql.named('SELECT COUNT(*) FROM activities WHERE 1=1$dateFilter'),
        parameters: parameters,
      );

      // Total students
      final studentsResult = await _connection!.execute(
        Sql.named('SELECT COUNT(*) FROM students'),
      );

      // Total registrations
      final regsResult = await _connection!.execute(
        Sql.named('''
          SELECT COUNT(*) FROM registrations r
          JOIN activities a ON r.activity_id = a.id
          WHERE 1=1$dateFilter
        '''),
        parameters: parameters,
      );

      // Total attendances
      final attendResult = await _connection!.execute(
        Sql.named('''
          SELECT COUNT(*) FROM attendances att
          JOIN activities a ON att.activity_id = a.id
          WHERE 1=1$dateFilter
        '''),
        parameters: parameters,
      );

      // Attendance rate
      final totalRegs = (regsResult.first[0] as int).toDouble();
      final totalAttend = (attendResult.first[0] as int).toDouble();
      final attendanceRate = totalRegs > 0 ? (totalAttend / totalRegs) * 100 : 0.0;

      // Activities by type
      final typeResult = await _connection!.execute(
        Sql.named('''
          SELECT activity_type, COUNT(*) as count
          FROM activities
          WHERE 1=1$dateFilter
          GROUP BY activity_type
          ORDER BY count DESC
        '''),
        parameters: parameters,
      );

      final activitiesByType = typeResult.map((row) => {
        'activity_type': row[0],
        'count': row[1],
      }).toList();

      // Top students
      final topStudentsResult = await _connection!.execute(
        Sql.named('''
          SELECT s.student_code, u.full_name, COUNT(att.id) as attendance_count
          FROM students s
          JOIN users u ON s.user_id = u.id
          LEFT JOIN attendances att ON s.id = att.student_id
          JOIN activities a ON att.activity_id = a.id
          WHERE 1=1$dateFilter
          GROUP BY s.id, s.student_code, u.full_name
          ORDER BY attendance_count DESC
          LIMIT 10
        '''),
        parameters: parameters,
      );

      final topStudents = topStudentsResult.map((row) => {
        'student_code': row[0],
        'full_name': row[1],
        'attendance_count': row[2],
      }).toList();

      return {
        'total_activities': activitiesResult.first[0],
        'total_students': studentsResult.first[0],
        'total_registrations': totalRegs.toInt(),
        'total_attendances': totalAttend.toInt(),
        'attendance_rate': attendanceRate,
        'activities_by_type': activitiesByType,
        'top_students': topStudents,
      };
    } catch (e) {
      print('Get statistics error: $e');
      return {};
    }
  }

  // ============ BACKUP METHODS ============

  Future<String> createBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFile = 'backup_$timestamp.sql';
      
      // Implement backup logic here
      // You might need to use pg_dump command or similar
      
      return backupFile;
    } catch (e) {
      print('Create backup error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBackups() async {
    // Implement backup list logic
    return [];
  }

  Future<void> restoreBackup(String backupFile) async {
    // Implement restore logic
  }

  Future<bool> deleteBackup(String backupFile) async {
    // Implement delete backup logic
    return true;
  }
}