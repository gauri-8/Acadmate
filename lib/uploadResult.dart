import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'models/course.dart';
import 'models/exam.dart'; // Import the Exam model
import 'models/user.dart' as local;

class UploadResultPage extends StatefulWidget {
  final String? courseId;

  const UploadResultPage({super.key, this.courseId});

  @override
  State<UploadResultPage> createState() => _UploadResultPageState();
}

class _UploadResultPageState extends State<UploadResultPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController marksController = TextEditingController();
  final TextEditingController maxMarksController = TextEditingController(text: '100');
  final TextEditingController remarksController = TextEditingController();

  List<Course> _courses = [];
  List<local.User> _students = [];
  List<Exam> _exams = []; // List to hold exams for the selected course
  bool _isLoading = false;
  String? _selectedCourseId;
  String? _selectedStudentId;
  String? _selectedExamId; // To hold the selected exam ID

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.courseId != null) {
      _selectedCourseId = widget.courseId;
      courseIdController.text = widget.courseId!;
      _onCourseSelected(widget.courseId!);
    }
  }

  Future<void> _loadInitialData() async {
    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()?['role'] == 'teacher') {
        final courses = await FirestoreService.getCoursesByTeacher(user.uid);
        setState(() => _courses = courses);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCourseSelected(String courseId) async {
    setState(() {
      _isLoading = true;
      _students.clear();
      _exams.clear();
      _selectedStudentId = null;
      _selectedExamId = null;
    });

    try {
      final students = await FirestoreService.getStudentsByCourse(courseId);
      // Fetch exams for the course
      final examsStream = FirestoreService.getCourseExams(courseId);
      final exams = await examsStream.first; // Get the first list from the stream

      setState(() {
        _students = students;
        _exams = exams;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading course details: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) return;

    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to upload results'), backgroundColor: Colors.red));
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      String? finalStudentUid;

      if (_selectedStudentId != null) {
        finalStudentUid = _selectedStudentId;
      } else {
        final typedId = studentIdController.text.trim();
        finalStudentUid = await FirestoreService.getUidFromStudentId(typedId);
        if (finalStudentUid == null) {
          throw Exception('Student with ID "$typedId" not found.');
        }
      }

      await FirestoreService.uploadResult(
        studentId: finalStudentUid!,
        courseId: _selectedCourseId ?? courseIdController.text,
        examId: _selectedExamId!, // Use the selected exam ID
        marks: double.parse(marksController.text),
        maxMarks: double.parse(maxMarksController.text),
        remarks: remarksController.text.isEmpty ? null : remarksController.text,
        uploadedBy: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Result uploaded successfully ✅"), backgroundColor: Colors.green));
      }

      _formKey.currentState!.reset();
      setState(() {
        studentIdController.clear();
        marksController.clear();
        remarksController.clear();
        _selectedStudentId = null;
        _selectedExamId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading result: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Result"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(labelText: "Select Course", border: OutlineInputBorder()),
                items: _courses.map((course) {
                  return DropdownMenuItem(value: course.id, child: Text('${course.name} (${course.code})'));
                }).toList(),
                onChanged: (courseId) {
                  if (courseId != null) {
                    setState(() {
                      _selectedCourseId = courseId;
                      courseIdController.text = courseId;
                    });
                    _onCourseSelected(courseId);
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a course' : null,
              ),
              const SizedBox(height: 16),

              // Student Dropdown (or text field if no students loaded)
              if (_students.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  decoration: const InputDecoration(labelText: "Select Student", border: OutlineInputBorder()),
                  items: _students.map((student) {
                    return DropdownMenuItem(value: student.id, child: Text('${student.name} (${student.email})'));
                  }).toList(),
                  onChanged: (studentId) => setState(() => _selectedStudentId = studentId),
                  validator: (value) => value == null || value.isEmpty ? 'Please select a student' : null,
                )
              else
                TextFormField(
                  controller: studentIdController,
                  decoration: const InputDecoration(labelText: "Student ID", border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter student ID' : null,
                ),
              const SizedBox(height: 16),

              // Exam Dropdown
              if (_exams.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedExamId,
                  decoration: const InputDecoration(labelText: 'Select Exam', border: OutlineInputBorder()),
                  items: _exams.map((exam) {
                    return DropdownMenuItem(value: exam.id, child: Text(exam.name));
                  }).toList(),
                  onChanged: (examId) {
                    setState(() {
                      _selectedExamId = examId;
                      // Optionally auto-fill max marks
                      final selectedExam = _exams.firstWhere((e) => e.id == examId);
                      maxMarksController.text = selectedExam.maxMarks.toString();
                    });
                  },
                  validator: (value) => value == null ? 'Please select an exam' : null,
                )
              else if (_selectedCourseId != null)
                const Text("No exams found for this course. Please create one in 'Manage Exams'."),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: marksController,
                      decoration: const InputDecoration(labelText: "Marks Obtained", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter marks';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: maxMarksController,
                      decoration: const InputDecoration(labelText: "Maximum Marks", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter max marks';
                        final max = double.tryParse(value);
                        if (max == null || max <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: "Remarks (Optional)", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Upload Result"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Confirmation Dialog and Helper Methods ---
  Future<bool> _showConfirmationDialog() async {
    // ... (rest of the helper methods like _showConfirmationDialog, _getStudentName, etc. can remain the same)
    // For brevity, I'm omitting them here as they don't need changes.
    // You can copy them from your previous version of the file.
    return true; // Placeholder
  }
}