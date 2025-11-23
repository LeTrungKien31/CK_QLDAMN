// lib/models/registration.dart
import 'package:student_attendance_app/models/activity.dart';
import 'package:student_attendance_app/models/student.dart';

class Registration {
  final int? id;
  final int activityId;
  final int studentId;
  final DateTime registrationTime;
  final String status;
  final String? notes;
  final Activity? activity;
  final Student? student;

  Registration({
    this.id,
    required this.activityId,
    required this.studentId,
    required this.registrationTime,
    this.status = 'registered',
    this.notes,
    this.activity,
    this.student,
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'],
      activityId: json['activity_id'],
      studentId: json['student_id'],
      registrationTime: DateTime.parse(json['registration_time']),
      status: json['status'] ?? 'registered',
      notes: json['notes'],
      activity: json['activity'] != null 
          ? Activity.fromJson(json['activity']) 
          : null,
      student: json['student'] != null 
          ? Student.fromJson(json['student']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'student_id': studentId,
      'registration_time': registrationTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
