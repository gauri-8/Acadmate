import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  final String id;
  final String studentId;
  final String courseId;
  final String examId;
  final double marks;
  final double maxMarks;
  final String grade; // "A+", "A", "B+", etc.
  final String remarks;
  final String uploadedBy;
  final DateTime uploadedAt;
  final bool isVerified;
  final String? verifiedBy;

  Result({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.examId,
    required this.marks,
    required this.maxMarks,
    required this.grade,
    required this.remarks,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.isVerified,
    this.verifiedBy,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "studentId": studentId,
    "courseId": courseId,
    "examId": examId,
    "marks": marks,
    "maxMarks": maxMarks,
    "grade": grade,
    "remarks": remarks,
    "uploadedBy": uploadedBy,
    "uploadedAt": Timestamp.fromDate(uploadedAt),
    "isVerified": isVerified,
    "verifiedBy": verifiedBy,
  };

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json["id"],
      studentId: json["studentId"],
      courseId: json["courseId"],
      examId: json["examId"],
      marks: json["marks"]?.toDouble() ?? 0.0,
      maxMarks: json["maxMarks"]?.toDouble() ?? 100.0,
      grade: json["grade"] ?? _calculateGrade(json["marks"]?.toDouble() ?? 0.0, json["maxMarks"]?.toDouble() ?? 100.0),
      remarks: json["remarks"] ?? "",
      uploadedBy: json["uploadedBy"],
      uploadedAt: (json["uploadedAt"] as Timestamp).toDate(),
      isVerified: json["isVerified"] ?? false,
      verifiedBy: json["verifiedBy"],
    );
  }

  Result copyWith({
    String? id,
    String? studentId,
    String? courseId,
    String? examId,
    double? marks,
    double? maxMarks,
    String? grade,
    String? remarks,
    String? uploadedBy,
    DateTime? uploadedAt,
    bool? isVerified,
    String? verifiedBy,
  }) {
    return Result(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      examId: examId ?? this.examId,
      marks: marks ?? this.marks,
      maxMarks: maxMarks ?? this.maxMarks,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  static String _calculateGrade(double marks, double maxMarks) {
    final percentage = (marks / maxMarks) * 100;
    
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 50) return "C+";
    if (percentage >= 40) return "C";
    return "F";
  }
}
