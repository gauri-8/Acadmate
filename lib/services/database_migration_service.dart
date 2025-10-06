import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/result.dart';
import '../models/academic_profile.dart';
import '../models/academic_year.dart';

class DatabaseMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate results from subcollection to centralized collection
  static Future<void> migrateResultsToCentralized() async {
    try {
      print('🔄 Starting results migration...');
      
      // Get all users with Results subcollections
      final usersSnapshot = await _firestore.collection('users').get();
      
      int migratedCount = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Check if user has Results subcollection
        final resultsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('Results')
            .get();
        
        if (resultsSnapshot.docs.isNotEmpty) {
          print('📋 Migrating ${resultsSnapshot.docs.length} results for user: $userId');
          
          // Migrate each result to centralized collection
          for (final resultDoc in resultsSnapshot.docs) {
            final data = resultDoc.data();
            
            // Create new result document in centralized collection
            final newResultData = {
              'studentId': userId,
              'courseId': data['courseId'] ?? 'unknown',
              'examId': data['examType'] ?? 'unknown', // Using examType as examId for now
              'marks': data['marks']?.toDouble() ?? 0.0,
              'maxMarks': data['maxMarks']?.toDouble() ?? 100.0,
              'grade': _calculateGrade(
                data['marks']?.toDouble() ?? 0.0, 
                data['maxMarks']?.toDouble() ?? 100.0
              ),
              'remarks': data['remarks'] ?? '',
              'uploadedBy': data['uploadedBy'] ?? 'unknown',
              'uploadedAt': data['timestamp'] ?? FieldValue.serverTimestamp(),
              'isVerified': false,
              'verifiedBy': null,
            };
            
            await _firestore.collection('results').add(newResultData);
            migratedCount++;
          }
          
          print('✅ Migrated results for user: $userId');
        }
      }
      
      print('🎉 Migration completed! Migrated $migratedCount results.');
      
    } catch (e) {
      print('❌ Migration failed: $e');
      throw Exception('Failed to migrate results: $e');
    }
  }

  /// Create academic profiles for existing students
  static Future<void> createAcademicProfiles() async {
    try {
      print('🔄 Creating academic profiles...');
      
      // Get all students
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      
      int profilesCreated = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Check if academic profile already exists
        final profileSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('academicProfile')
            .doc('current')
            .get();
        
        if (!profileSnapshot.exists) {
          // Create academic profile
          final profileData = {
            'userId': userId,
            'spi': userData['spi']?.toDouble() ?? 0.0,
            'cpi': userData['cpi']?.toDouble() ?? 0.0,
            'attendancePercentage': userData['attendancePercentage']?.toDouble() ?? 0.0,
            'semester': 'Fall 2024', // Default semester
            'academicYear': '2024-25', // Default academic year
            'lastUpdated': FieldValue.serverTimestamp(),
          };
          
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('academicProfile')
              .doc('current')
              .set(profileData);
          
          profilesCreated++;
          print('📊 Created academic profile for user: $userId');
        }
      }
      
      print('🎉 Academic profiles created! Created $profilesCreated profiles.');
      
    } catch (e) {
      print('❌ Failed to create academic profiles: $e');
      throw Exception('Failed to create academic profiles: $e');
    }
  }

  /// Create default academic year
  static Future<void> createDefaultAcademicYear() async {
    try {
      print('🔄 Creating default academic year...');
      
      // Check if academic year already exists
      final yearSnapshot = await _firestore
          .collection('academicYears')
          .doc('2024-25')
          .get();
      
      if (!yearSnapshot.exists) {
        final yearData = {
          'year': '2024-25',
          'semesters': ['Fall 2024', 'Spring 2025'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('academicYears')
            .doc('2024-25')
            .set(yearData);
        
        print('📅 Created default academic year: 2024-25');
      } else {
        print('📅 Academic year 2024-25 already exists');
      }
      
    } catch (e) {
      print('❌ Failed to create academic year: $e');
      throw Exception('Failed to create academic year: $e');
    }
  }

  /// Run complete migration
  static Future<void> runCompleteMigration() async {
    try {
      print('🚀 Starting complete database migration...');
      
      // Step 1: Create default academic year
      await createDefaultAcademicYear();
      
      // Step 2: Create academic profiles
      await createAcademicProfiles();
      
      // Step 3: Migrate results (optional - only if you want to move from subcollection)
      // await migrateResultsToCentralized();
      
      print('🎉 Complete migration finished successfully!');
      
    } catch (e) {
      print('❌ Complete migration failed: $e');
      throw Exception('Complete migration failed: $e');
    }
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
