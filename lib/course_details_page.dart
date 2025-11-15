import 'package:flutter/material.dart';
import 'package:acadmate/models/course.dart';
import 'package:acadmate/models/user.dart' as local_user;
import 'package:acadmate/services/firestore_service.dart';
import 'package:acadmate/uploadResult.dart';
import 'package:acadmate/manage_exams_page.dart';

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
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Course Info Header
          ListTile(
            title: Text(widget.course.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            subtitle: Text(widget.course.code, style: const TextStyle(fontSize: 18)),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              child: Text(
                widget.course.code.substring(0, 2),
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const Divider(height: 32),

          // Quick Actions for this course
          Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 16),
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
                // --- THIS IS THE UPDATE ---
                // Pass the current course to the ManageExamsPage
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ManageExamsPage(course: widget.course)
                ));
              }
          ),
          const SizedBox(height: 24),

          // Enrolled Students List
          Text('Enrolled Students (${_students.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
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