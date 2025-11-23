// lib/models/attendance.dart
import 'package:student_attendance_app/models/activity.dart';
import 'package:student_attendance_app/models/student.dart';

class Attendance {
  final int? id;
  final int registrationId;
  final int activityId;
  final int studentId;
  final DateTime attendanceTime;
  final String attendanceMethod;
  final String status;
  final int? recordedBy;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final Student? student;
  final Activity? activity;

  Attendance({
    this.id,
    required this.registrationId,
    required this.activityId,
    required this.studentId,
    required this.attendanceTime,
    required this.attendanceMethod,
    this.status = 'present',
    this.recordedBy,
    this.notes,
    this.latitude,
    this.longitude,
    this.student,
    this.activity,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      registrationId: json['registration_id'],
      activityId: json['activity_id'],
      studentId: json['student_id'],
      attendanceTime: DateTime.parse(json['attendance_time']),
      attendanceMethod: json['attendance_method'],
      status: json['status'] ?? 'present',
      recordedBy: json['recorded_by'],
      notes: json['notes'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      student: json['student'] != null 
          ? Student.fromJson(json['student']) 
          : null,
      activity: json['activity'] != null 
          ? Activity.fromJson(json['activity']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_id': registrationId,
      'activity_id': activityId,
      'student_id': studentId,
      'attendance_time': attendanceTime.toIso8601String(),
      'attendance_method': attendanceMethod,
      'status': status,
      'recorded_by': recordedBy,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool isPresent() => status == 'present';
  bool isAbsent() => status == 'absent';
  bool isLate() => status == 'late';
  bool isExcused() => status == 'excused';
}