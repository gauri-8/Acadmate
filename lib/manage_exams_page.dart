import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/course.dart';
import 'models/exam.dart';

class ManageExamsPage extends StatefulWidget {
  // Can be initialized with a specific course
  final Course? course;

  const ManageExamsPage({super.key, this.course});

  @override
  State<ManageExamsPage> createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends State<ManageExamsPage> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();
  final _examTypeController = TextEditingController();
  final _maxMarksController = TextEditingController();
  final _passingMarksController = TextEditingController();
  final _weightageController = TextEditingController();

  String? _selectedCourseId;
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      // If a course is provided, use it directly
      _selectedCourseId = widget.course!.id;
      _courses = [widget.course!];
      _isLoading = false;
    } else {
      // Otherwise, load all courses for the teacher
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final courses = await FirestoreService.getCoursesByTeacher(user.uid);
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course != null ? "${widget.course!.code} Exams" : "Manage Exams"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCourseSelector(),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedCourseId == null
                  ? const Center(child: Text('Please select a course to see the exams.'))
                  : _buildExamsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedCourseId == null
          ? null
          : FloatingActionButton(
        onPressed: () => _showCreateExamDialog(),
        backgroundColor: Colors.blue[600],
        tooltip: 'Create New Exam',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCourseSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCourseId,
      // Disable dropdown if a course was passed in
      onChanged: widget.course != null ? null : (value) {
        setState(() {
          _selectedCourseId = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Select a Course',
        border: const OutlineInputBorder(),
        // Grey out if disabled
        filled: widget.course != null,
        fillColor: widget.course != null ? Colors.grey[200] : Colors.transparent,
      ),
      items: _courses.map((course) {
        return DropdownMenuItem(
          value: course.id,
          child: Text('${course.name} (${course.code})'),
        );
      }).toList(),
    );
  }

  Widget _buildExamsList() {
    return StreamBuilder<List<Exam>>(
      stream: FirestoreService.getCourseExams(_selectedCourseId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No exams found for this course.'));
        }

        final exams = snapshot.data!;
        return ListView.builder(
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Type: ${exam.examType}, Max Marks: ${exam.maxMarks}'),
                trailing: Text('${exam.weightage}%', style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateExamDialog() {
    // Clear controllers before showing
    _examNameController.clear();
    _examTypeController.clear();
    _maxMarksController.clear();
    _passingMarksController.clear();
    _weightageController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Exam'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _examNameController,
                    decoration: const InputDecoration(labelText: 'Exam Name'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter an exam name' : null,
                  ),
                  TextFormField(
                    controller: _examTypeController,
                    decoration:
                    const InputDecoration(labelText: 'Exam Type (e.g., Midterm)'),
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter an exam type' : null,
                  ),
                  TextFormField(
                    controller: _maxMarksController,
                    decoration: const InputDecoration(labelText: 'Max Marks'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter max marks' : null,
                  ),
                  TextFormField(
                    controller: _passingMarksController,
                    decoration:
                    const InputDecoration(labelText: 'Passing Marks'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter passing marks' : null,
                  ),
                  TextFormField(
                    controller: _weightageController,
                    decoration:
                    const InputDecoration(labelText: 'Weightage (%)'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter a weightage' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createExam,
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirestoreService.createExam(
        courseId: _selectedCourseId!,
        name: _examNameController.text,
        examType: _examTypeController.text,
        maxMarks: double.parse(_maxMarksController.text),
        passingMarks: double.parse(_passingMarksController.text),
        weightage: double.parse(_weightageController.text),
        createdBy: user.uid,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating exam: $e')),
        );
      }
    }
  }
}