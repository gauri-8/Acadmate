import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String message;
  final String type; // "result", "announcement", "reminder"
  final List<String> targetUsers; // userIds
  final List<String> targetRoles; // ["student", "teacher"]
  final bool isRead;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetUsers,
    required this.targetRoles,
    required this.isRead,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "message": message,
    "type": type,
    "targetUsers": targetUsers,
    "targetRoles": targetRoles,
    "isRead": isRead,
    "createdBy": createdBy,
    "createdAt": Timestamp.fromDate(createdAt),
    "expiresAt": expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
  };

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json["id"],
      title: json["title"],
      message: json["message"],
      type: json["type"],
      targetUsers: List<String>.from(json["targetUsers"] ?? []),
      targetRoles: List<String>.from(json["targetRoles"] ?? []),
      isRead: json["isRead"] ?? false,
      createdBy: json["createdBy"],
      createdAt: (json["createdAt"] as Timestamp).toDate(),
      expiresAt: json["expiresAt"] != null 
          ? (json["expiresAt"] as Timestamp).toDate() 
          : null,
    );
  }

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    List<String>? targetUsers,
    List<String>? targetRoles,
    bool? isRead,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUsers: targetUsers ?? this.targetUsers,
      targetRoles: targetRoles ?? this.targetRoles,
      isRead: isRead ?? this.isRead,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
