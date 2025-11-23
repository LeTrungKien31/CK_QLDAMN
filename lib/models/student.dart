// lib/models/student.dart
import 'package:student_attendance_app/models/user.dart';

class Student {
  final int? id;
  final int userId;
  final String studentCode;
  final String? className;
  final String? major;
  final String? academicYear;
  final DateTime? dateOfBirth;
  final String? address;
  final User? user;

  Student({
    this.id,
    required this.userId,
    required this.studentCode,
    this.className,
    this.major,
    this.academicYear,
    this.dateOfBirth,
    this.address,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      userId: json['user_id'],
      studentCode: json['student_code'],
      className: json['class_name'],
      major: json['major'],
      academicYear: json['academic_year'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      address: json['address'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'student_code': studentCode,
      'class_name': className,
      'major': major,
      'academic_year': academicYear,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
    };
  }
}
