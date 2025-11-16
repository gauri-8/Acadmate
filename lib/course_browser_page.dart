import 'package:flutter/material.dart';
import 'package:acadmate/models/course.dart';
import 'package:acadmate/models/user.dart';
import 'package:acadmate/services/firestore_service.dart';

class CourseBrowserPage extends StatefulWidget {
  const CourseBrowserPage({super.key});

  @override
  State<CourseBrowserPage> createState() => _CourseBrowserPageState();
}

class _CourseBrowserPageState extends State<CourseBrowserPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Course>> _coursesFuture;
  late Future<List<User>> _teachersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _coursesFuture = FirestoreService.getAllCourses();
    _teachersFuture = FirestoreService.getAllTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses & Faculty'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Courses', icon: Icon(Icons.school)),
            Tab(text: 'Faculty', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCoursesTab(),
          _buildFacultyTab(),
        ],
      ),
    );
  }

  // --- Tab for All Courses ---
  Widget _buildCoursesTab() {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No courses found.'));
        }

        final courses = snapshot.data!;
        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(26),
                  child: Text(
                    course.code.substring(0, 2),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(course.code),
                // We can add an onTap later to show more details
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab for All Faculty ---
  Widget _buildFacultyTab() {
    return FutureBuilder<List<User>>(
      future: _teachersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No faculty found.'));
        }

        final teachers = snapshot.data!;
        return ListView.builder(
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(teacher.name.isNotEmpty ? teacher.name[0] : 'T'),
                ),
                title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(teacher.email),
              ),
            );
          },
        );
      },
    );
  }
}