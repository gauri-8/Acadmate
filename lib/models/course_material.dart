import 'package:cloud_firestore/cloud_firestore.dart';

class CourseMaterial {
  final String id;
  final String title;
  final String fileUrl; // URL from Firebase Storage
  final String fileName;
  final String fileType; // e.g., "pdf", "ppt", "doc"
  final String uploadedBy; // Teacher's UID
  final DateTime uploadedAt;

  CourseMaterial({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory CourseMaterial.fromJson(Map<String, dynamic> json, String id) {
    return CourseMaterial(
      id: id,
      title: json['title'] ?? 'Untitled',
      fileUrl: json['fileUrl'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? 'file',
      uploadedBy: json['uploadedBy'] ?? '',
      uploadedAt: (json['uploadedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}