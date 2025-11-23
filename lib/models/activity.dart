// lib/models/activity.dart
import 'package:student_attendance_app/models/user.dart';

class Activity {
  final int? id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? registrationDeadline;
  final int? maxParticipants;
  final String? activityType;
  final int? organizerId;
  final String status;
  final String? imageUrl;
  final DateTime? createdAt;
  final User? organizer;
  final int? registeredCount;
  final int? attendedCount;

  Activity({
    this.id,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.registrationDeadline,
    this.maxParticipants,
    this.activityType,
    this.organizerId,
    this.status = 'upcoming',
    this.imageUrl,
    this.createdAt,
    this.organizer,
    this.registeredCount,
    this.attendedCount,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      registrationDeadline: json['registration_deadline'] != null 
          ? DateTime.parse(json['registration_deadline']) 
          : null,
      maxParticipants: json['max_participants'],
      activityType: json['activity_type'],
      organizerId: json['organizer_id'],
      status: json['status'] ?? 'upcoming',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      organizer: json['organizer'] != null 
          ? User.fromJson(json['organizer']) 
          : null,
      registeredCount: json['registered_count'],
      attendedCount: json['attended_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'max_participants': maxParticipants,
      'activity_type': activityType,
      'organizer_id': organizerId,
      'status': status,
      'image_url': imageUrl,
    };
  }

  bool isUpcoming() => status == 'upcoming';
  bool isOngoing() => status == 'ongoing';
  bool isCompleted() => status == 'completed';
  bool isCancelled() => status == 'cancelled';
}