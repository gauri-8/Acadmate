import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'profilePage.dart';
import 'viewResult.dart';
import 'uploadResult.dart';
import 'manage_exams_page.dart';
import 'send_notification_page.dart'; // Import the new page
import 'notifications_page.dart'; // Import the new page
import 'migration_page.dart';
import 'models/academic_profile.dart';
import 'services/firestore_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  Future<AcademicProfile?> _getStudentAcademicProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      return await FirestoreService.getAcademicProfile(user.uid);
    } catch (e) {
      debugPrint("Error fetching academic profile: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AcadMate'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(userId: user.uid),
                  ),
                );
              }
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getUserRole(),
        builder: (context, snapshot) {
          final role = snapshot.data ?? 'student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[400]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 18, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? 'No email', style: const TextStyle(fontSize: 14, color: Colors.white60)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 16),
                _buildActionCard(
                  context: context,
                  title: 'View Results',
                  subtitle: 'Check your academic performance',
                  icon: Icons.assessment,
                  color: Colors.green,
                  onTap: () {
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentResultsPage(studentId: user.uid)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (role == 'teacher') ...[
                  _buildActionCard(
                    context: context,
                    title: 'Upload Results',
                    subtitle: 'Add new exam results for students',
                    icon: Icons.upload_file,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadResultPage())),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context: context,
                    title: 'Manage Exams',
                    subtitle: 'Create and view course exams',
                    icon: Icons.edit_note,
                    color: Colors.cyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageExamsPage())),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard( // New Card for Sending Notifications
                    context: context,
                    title: 'Send Notification',
                    subtitle: 'Broadcast messages to students',
                    icon: Icons.campaign,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SendNotificationPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildActionCard(
                  context: context,
                  title: 'Database Migration',
                  subtitle: 'Migrate to new database structure',
                  icon: Icons.storage,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MigrationPage())),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: 'Profile',
                  subtitle: 'View and edit your profile',
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () {
                    if (user != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: user.uid)));
                    }
                  },
                ),
                const SizedBox(height: 24),
                if (role == 'student') ...[
                  Text('Academic Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 16),
                  _buildStatsCard(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return FutureBuilder<AcademicProfile?>(
      future: _getStudentAcademicProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          );
        }

        final profile = snapshot.data;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('SPI', profile?.spi.toStringAsFixed(2) ?? 'N/A', Colors.blue),
                _buildStatItem('CPI', profile?.cpi.toStringAsFixed(2) ?? 'N/A', Colors.green),
                _buildStatItem('Attendance', '${profile?.attendancePercentage.toStringAsFixed(1) ?? 'N/A'}%', Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}