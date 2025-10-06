import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String id;
  final String courseId;
  final String name;
  final String examType; // "quiz", "midterm", "final", "assignment"
  final double maxMarks;
  final double passingMarks;
  final double weightage; // percentage
  final DateTime? scheduledDate;
  final DateTime? conductedDate;
  final bool isPublished;
  final String createdBy; // facultyId
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.courseId,
    required this.name,
    required this.examType,
    required this.maxMarks,
    required this.passingMarks,
    required this.weightage,
    this.scheduledDate,
    this.conductedDate,
    required this.isPublished,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "courseId": courseId,
    "name": name,
    "examType": examType,
    "maxMarks": maxMarks,
    "passingMarks": passingMarks,
    "weightage": weightage,
    "scheduledDate": scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
    "conductedDate": conductedDate != null ? Timestamp.fromDate(conductedDate!) : null,
    "isPublished": isPublished,
    "createdBy": createdBy,
    "createdAt": Timestamp.fromDate(createdAt),
  };

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json["id"],
      courseId: json["courseId"],
      name: json["name"],
      examType: json["examType"],
      maxMarks: json["maxMarks"]?.toDouble() ?? 100.0,
      passingMarks: json["passingMarks"]?.toDouble() ?? 40.0,
      weightage: json["weightage"]?.toDouble() ?? 0.0,
      scheduledDate: json["scheduledDate"] != null 
          ? (json["scheduledDate"] as Timestamp).toDate() 
          : null,
      conductedDate: json["conductedDate"] != null 
          ? (json["conductedDate"] as Timestamp).toDate() 
          : null,
      isPublished: json["isPublished"] ?? false,
      createdBy: json["createdBy"],
      createdAt: (json["createdAt"] as Timestamp).toDate(),
    );
  }

  Exam copyWith({
    String? id,
    String? courseId,
    String? name,
    String? examType,
    double? maxMarks,
    double? passingMarks,
    double? weightage,
    DateTime? scheduledDate,
    DateTime? conductedDate,
    bool? isPublished,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Exam(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      examType: examType ?? this.examType,
      maxMarks: maxMarks ?? this.maxMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      weightage: weightage ?? this.weightage,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      conductedDate: conductedDate ?? this.conductedDate,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
