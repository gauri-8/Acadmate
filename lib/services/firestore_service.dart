import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import '../models/user.dart';
import '../models/course.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Result operations
  static Future<String> uploadResult({
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
        "studentId": studentId,
        "courseId": courseId,
        "examType": examType,
        "marks": marks,
        "maxMarks": maxMarks,
        "remarks": remarks,
        "uploadedAt": FieldValue.serverTimestamp(),
        "uploadedBy": uploadedBy,
      };

      final docRef = await _firestore.collection("results").add(resultData);
      return docRef.id;
    } catch (e) {
      throw Exception("Failed to upload result: $e");
    }
  }

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

  // User operations
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

  // Course operations
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

  // Validation methods
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
}
