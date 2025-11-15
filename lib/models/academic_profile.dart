import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicProfile {
  final String id;
  final String userId;
  final double spi;
  final double cpi;
  final double attendancePercentage;
  final String semester;
  final String academicYear;
  final DateTime lastUpdated;

  AcademicProfile({
    required this.id,
    required this.userId,
    required this.spi,
    required this.cpi,
    required this.attendancePercentage,
    required this.semester,
    required this.academicYear,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "spi": spi,
    "cpi": cpi,
    "attendancePercentage": attendancePercentage,
    "semester": semester,
    "academicYear": academicYear,
    "lastUpdated": Timestamp.fromDate(lastUpdated),
  };

  factory AcademicProfile.fromJson(Map<String, dynamic> json) {
    return AcademicProfile(
      id: json["id"] ?? '', // Provides a default empty string if null
      userId: json["userId"] ?? '', // Provides a default empty string if null
      spi: json["spi"]?.toDouble() ?? 0.0,
      cpi: json["cpi"]?.toDouble() ?? 0.0,
      attendancePercentage: json["attendancePercentage"]?.toDouble() ?? 0.0,
      semester: json["semester"] ?? "",
      academicYear: json["academicYear"] ?? "",
      lastUpdated: json["lastUpdated"] is Timestamp
          ? (json["lastUpdated"] as Timestamp).toDate()
          : DateTime.now(), // Fallback to current time
    );
  }

  AcademicProfile copyWith({
    String? id,
    String? userId,
    double? spi,
    double? cpi,
    double? attendancePercentage,
    String? semester,
    String? academicYear,
    DateTime? lastUpdated,
  }) {
    return AcademicProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spi: spi ?? this.spi,
      cpi: cpi ?? this.cpi,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}