import 'package:cloud_firestore/cloud_firestore.dart';

class Result {
  final String id;
  final String studentId;
  final String courseId;
  final String examType;
  final double marks;
  final double maxMarks;
  final String remarks;
  final DateTime uploadedAt;
  final String uploadedBy;

  Result({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.examType,
    required this.marks,
    required this.maxMarks,
    required this.remarks,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "studentId": studentId,
        "courseId": courseId,
        "examType": examType,
        "marks": marks,
        "maxMarks": maxMarks,
        "remarks": remarks,
        "uploadedAt": uploadedAt,
        "uploadedBy": uploadedBy,
      };

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: json["id"],
      studentId: json["studentId"],
      courseId: json["courseId"],
      examType: json["examType"],
      marks: json["marks"].toDouble(),
      maxMarks: json["maxMarks"]?.toDouble() ?? 100.0,
      remarks: json["remarks"],
      uploadedAt: (json["uploadedAt"] as Timestamp).toDate(),
      uploadedBy: json["uploadedBy"],
    );
  }
}
