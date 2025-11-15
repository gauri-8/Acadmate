import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id; // Document ID (e.g., "2025-11-17")
  final DateTime date;
  final Map<String, String> statuses; // { "studentId": "present", ... }

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.statuses,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json, String id) {
    return AttendanceRecord(
      id: id,
      date: (json['date'] as Timestamp).toDate(),
      statuses: Map<String, String>.from(json['statuses'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'statuses': statuses,
    };
  }
}