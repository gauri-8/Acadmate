import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // e.g., "class", "holiday", "exam"
  final String? courseId; // Optional: link event to a course
  final String createdBy; // The UID of the user who created it
  final List<String> targetRoles; // e.g., ["student", "teacher"]

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.courseId,
    required this.createdBy,
    required this.targetRoles,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      type: json['type'] ?? 'general',
      courseId: json['courseId'],
      createdBy: json['createdBy'] ?? '', // <-- THIS IS THE FIX
      targetRoles: List<String>.from(json['targetRoles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': Timestamp.fromDate(date),
    'type': type,
    'courseId': courseId,
    'createdBy': createdBy,
    'targetRoles': targetRoles,
  };
}