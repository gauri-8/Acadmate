import 'package:flutter/material.dart';
import 'package:acadmate/models/course.dart';
import 'package:acadmate/models/user.dart' as local_user;
import 'package:acadmate/services/firestore_service.dart';
import 'package:acadmate/uploadResult.dart';
import 'package:acadmate/manage_exams_page.dart';
import 'package:acadmate/attendance_page.dart'; // <-- 1. IMPORT THE NEW PAGE

class CourseDetailsPage extends StatefulWidget {
  final Course course;

  const CourseDetailsPage({super.key, required this.course});

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  List<local_user.User> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await FirestoreService.getStudentsByCourse(widget.course.id);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Course Info Header
          ListTile(
            title: Text(widget.course.name, style: Theme.of(context).textTheme.headlineSmall),
            subtitle: Text(widget.course.code, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor.withAlpha(26),
              child: Text(
                widget.course.code.substring(0, 2),
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const Divider(height: 32),

          // Quick Actions for this course
          Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // --- 2. ADD THE "TAKE ATTENDANCE" CARD ---
          _buildActionCard(
              context: context,
              title: "Take Attendance",
              subtitle: "Mark attendance for ${widget.course.code}",
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => AttendancePage(course: widget.course)
                ));
              }
          ),
          const SizedBox(height: 12),

          _buildActionCard(
              context: context,
              title: "Upload Results",
              subtitle: "Upload grades for ${widget.course.code}",
              icon: Icons.upload_file,
              color: Colors.orange,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => UploadResultPage(courseId: widget.course.id)
                ));
              }
          ),
          const SizedBox(height: 12),
          _buildActionCard(
              context: context,
              title: "Manage Exams",
              subtitle: "View/Edit exams for ${widget.course.code}",
              icon: Icons.edit_note,
              color: Colors.cyan,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ManageExamsPage(course: widget.course)
                ));
              }
          ),
          const SizedBox(height: 24),

          // Enrolled Students List
          Text('Enrolled Students (${_students.length})', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStudentList(),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_students.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No students are enrolled in this course.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(student.name.isNotEmpty ? student.name[0] : 'U'),
            ),
            title: Text(student.name),
            subtitle: Text(student.email),
          ),
        );
      },
    );
  }
}

// Helper widget
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
              // --- 3. FIX THE DEPRECATION WARNING ---
              decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(12)),
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