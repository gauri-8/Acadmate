import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/academic_profile.dart';
import '../models/exam.dart';
import '../models/academic_year.dart';
import '../models/notification.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> uploadResult({
    required String studentId,
    required String courseId,
    required String examId,
    required double marks,
    required double maxMarks,
    String? remarks,
    required String uploadedBy,
  }) async {
    try {
      final grade = _calculateGrade(marks, maxMarks);
      
      final resultData = {
        "studentId": studentId,
        "courseId": courseId,
        "examId": examId,
        "marks": marks,
        "maxMarks": maxMarks,
        "grade": grade,
        "remarks": remarks ?? "",
        "uploadedBy": uploadedBy,
        "uploadedAt": FieldValue.serverTimestamp(),
        "isVerified": false,
        "verifiedBy": null,
      };

      final docRef = await _firestore.collection("results").add(resultData);
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to upload result: $e");
    }
  }

  // Legacy method for backward compatibility
  static Future<String> uploadResultLegacy({
    required String studentId,
    required String courseId,
    required String examType,
    required double marks,
    required double maxMarks,
    String? remarks,
    required String uploadedBy,
  }) async {
    try {
      final resultData = {
        "courseId": courseId,
        "examType": examType,
        "marks": marks,
        "maxMarks": maxMarks,
        "remarks": remarks,
        "timestamp": FieldValue.serverTimestamp(),
        "uploadedBy": uploadedBy,
      };

      final docRef = await _firestore
          .collection("users")
          .doc(studentId)
          .collection("Results")
          .add(resultData);
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to upload result: $e");
    }
  }

  // New centralized results query
  static Stream<List<Result>> getStudentResults(String studentId) {
    return _firestore
        .collection("results")
        .where("studentId", isEqualTo: studentId)
        .orderBy("uploadedAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Result.fromJson(data);
      }).toList();
    });
  }

  // Legacy method for backward compatibility
  static Stream<List<Result>> getStudentResultsLegacy(String studentId) {
    return _firestore
        .collection("users")
        .doc(studentId)
        .collection("Results")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Convert legacy format to new format
        data['examId'] = data['examType'] ?? 'unknown';
        data['grade'] = _calculateGrade(data['marks']?.toDouble() ?? 0.0, data['maxMarks']?.toDouble() ?? 100.0);
        data['uploadedAt'] = data['timestamp'];
        data['isVerified'] = false;
        data['verifiedBy'] = null;
        return Result.fromJson(data);
      }).toList();
    });
  }

  static Future<List<Result>> getCourseResults(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection("results")
          .where("courseId", isEqualTo: courseId)
          .orderBy("uploadedAt", descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Result.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception("Failed to get course results: $e");
    }
  }

  static Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection("users").doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get user: $e");
    }
  }

  static Stream<User?> getUserStream(String userId) {
    return _firestore.collection("users").doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return User.fromJson(data);
      }
      return null;
    });
  }

  static Future<List<User>> getStudentsByCourse(String courseId) async {
    try {
      final courseDoc = await _firestore.collection("courses").doc(courseId).get();
      if (!courseDoc.exists) return [];
      
      final courseData = courseDoc.data()!;
      final studentIds = List<String>.from(courseData['studentIds'] ?? []);
      
      if (studentIds.isEmpty) return [];
      
      final snapshot = await _firestore
          .collection("users")
          .where(FieldPath.documentId, whereIn: studentIds)
          .where("role", isEqualTo: "student")
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception("Failed to get students by course: $e");
    }
  }

  static Future<List<Course>> getCoursesByTeacher(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection("courses")
          .where("facultyId", isEqualTo: teacherId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Course.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception("Failed to get courses by teacher: $e");
    }
  }

  static Future<Course?> getCourse(String courseId) async {
    try {
      final doc = await _firestore.collection("courses").doc(courseId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Course.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get course: $e");
    }
  }

  static Future<bool> isStudentEnrolledInCourse(String studentId, String courseId) async {
    try {
      final course = await getCourse(courseId);
      return course?.studentIds.contains(studentId) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> canTeacherAccessCourse(String teacherId, String courseId) async {
    try {
      final course = await getCourse(courseId);
      return course?.facultyId == teacherId;
    } catch (e) {
      return false;
    }
  }

  // Academic Profile Methods
  static Future<AcademicProfile?> getAcademicProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection("users")
          .doc(userId)
          .collection("academicProfile")
          .doc("current")
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return AcademicProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get academic profile: $e");
    }
  }

  static Future<void> updateAcademicProfile(String userId, AcademicProfile profile) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("academicProfile")
          .doc("current")
          .set(profile.toJson());
    } catch (e) {
      throw Exception("Failed to update academic profile: $e");
    }
  }

  // Exam Methods
  static Future<String> createExam({
    required String courseId,
    required String name,
    required String examType,
    required double maxMarks,
    required double passingMarks,
    required double weightage,
    DateTime? scheduledDate,
    required String createdBy,
  }) async {
    try {
      final examData = {
        "courseId": courseId,
        "name": name,
        "examType": examType,
        "maxMarks": maxMarks,
        "passingMarks": passingMarks,
        "weightage": weightage,
        "scheduledDate": scheduledDate != null ? Timestamp.fromDate(scheduledDate) : null,
        "conductedDate": null,
        "isPublished": false,
        "createdBy": createdBy,
        "createdAt": FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection("courses")
          .doc(courseId)
          .collection("exams")
          .add(examData);
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to create exam: $e");
    }
  }

  static Stream<List<Exam>> getCourseExams(String courseId) {
    return _firestore
        .collection("courses")
        .doc(courseId)
        .collection("exams")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Exam.fromJson(data);
      }).toList();
    });
  }

  // Notification Methods
  static Future<String> createNotification({
    required String title,
    required String message,
    required String type,
    required List<String> targetUsers,
    required List<String> targetRoles,
    required String createdBy,
    DateTime? expiresAt,
  }) async {
    try {
      final notificationData = {
        "title": title,
        "message": message,
        "type": type,
        "targetUsers": targetUsers,
        "targetRoles": targetRoles,
        "isRead": false,
        "createdBy": createdBy,
        "createdAt": FieldValue.serverTimestamp(),
        "expiresAt": expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      };

      final docRef = await _firestore.collection("notifications").add(notificationData);
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to create notification: $e");
    }
  }

  static Stream<List<Notification>> getUserNotifications(String userId) {
    return _firestore
        .collection("notifications")
        .where("targetUsers", arrayContains: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Notification.fromJson(data);
      }).toList();
    });
  }

  // Utility Methods
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
