import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYear {
  final String id;
  final String year; // e.g., "2024-25"
  final List<String> semesters; // ["Fall 2024", "Spring 2025"]
  final bool isActive;
  final DateTime createdAt;

  AcademicYear({
    required this.id,
    required this.year,
    required this.semesters,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "year": year,
    "semesters": semesters,
    "isActive": isActive,
    "createdAt": Timestamp.fromDate(createdAt),
  };

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      id: json["id"],
      year: json["year"],
      semesters: List<String>.from(json["semesters"] ?? []),
      isActive: json["isActive"] ?? false,
      createdAt: (json["createdAt"] as Timestamp).toDate(),
    );
  }

  AcademicYear copyWith({
    String? id,
    String? year,
    List<String>? semesters,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AcademicYear(
      id: id ?? this.id,
      year: year ?? this.year,
      semesters: semesters ?? this.semesters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
