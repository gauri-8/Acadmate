import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';
import 'models/course.dart';
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
  final TextEditingController examTypeController = TextEditingController();
  final TextEditingController marksController = TextEditingController();
  final TextEditingController maxMarksController =
  TextEditingController(text: '100');
  final TextEditingController remarksController = TextEditingController();

  List<Course> _courses = [];
  List<local.User> _students = [];
  bool _isLoading = false;
  String? _selectedCourseId;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.courseId != null) {
      _selectedCourseId = widget.courseId;
      courseIdController.text = widget.courseId!;
      _loadStudentsForCourse(widget.courseId!);
    }
  }

  Future<void> _loadData() async {
    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data()?['role'] == 'teacher') {
        final courses = await FirestoreService.getCoursesByTeacher(user.uid);
        setState(() => _courses = courses);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudentsForCourse(String courseId) async {
    setState(() => _isLoading = true);
    try {
      final students = await FirestoreService.getStudentsByCourse(courseId);
      setState(() => _students = students);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) return;

    final auth.User? user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to upload results'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      String? finalStudentUid;

      // If a student was selected from the dropdown, we use their UID directly.
      if (_selectedStudentId != null) {
        finalStudentUid = _selectedStudentId;
      } else {
        // If the teacher typed an ID, we look up the UID using the numeric studentId.
        final typedId = studentIdController.text.trim();
        finalStudentUid = await FirestoreService.getUidFromStudentId(typedId);

        if (finalStudentUid == null) {
          throw Exception('Student with ID "$typedId" not found.');
        }
      }

      // Now, use the confirmed finalStudentUid to upload the result.
      await FirestoreService.uploadResult(
        studentId: finalStudentUid!, // This is now guaranteed to be the UID
        courseId: _selectedCourseId ?? courseIdController.text,
        examId: examTypeController.text,
        marks: double.parse(marksController.text),
        maxMarks: double.parse(maxMarksController.text),
        remarks: remarksController.text.isEmpty ? null : remarksController.text,
        uploadedBy: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Result uploaded successfully ✅"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      _formKey.currentState!.reset();
      setState(() {
        studentIdController.clear();
        examTypeController.clear();
        marksController.clear();
        remarksController.clear();
        _selectedStudentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final marks = double.tryParse(marksController.text) ?? 0;
    final maxMarks = double.tryParse(maxMarksController.text) ?? 100;
    final percentage = maxMarks > 0 ? (marks / maxMarks * 100).round() : 0;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.upload_file,
                color: Colors.blue[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text("Confirm Upload"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please review the result details before uploading:",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildConfirmationRow("Student", _getStudentName()),
              _buildConfirmationRow("Course", _getCourseName()),
              _buildConfirmationRow("Exam Type", examTypeController.text),
              _buildConfirmationRow(
                  "Marks",
                  "${marks.toStringAsFixed(1)} / ${maxMarks.toStringAsFixed(1)}"),
              _buildConfirmationRow("Percentage", "$percentage%"),
              if (remarksController.text.isNotEmpty)
                _buildConfirmationRow("Remarks", remarksController.text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text("Upload Result"),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowPreview() {
    return (studentIdController.text.isNotEmpty ||
        _selectedStudentId != null) &&
        (courseIdController.text.isNotEmpty || _selectedCourseId != null) &&
        examTypeController.text.isNotEmpty &&
        marksController.text.isNotEmpty;
  }

  String _getStudentName() {
    if (_selectedStudentId != null) {
      try {
        return _students.firstWhere((s) => s.id == _selectedStudentId).name;
      } catch (e) {
        return studentIdController.text;
      }
    }
    return studentIdController.text;
  }

  String _getCourseName() {
    if (_selectedCourseId != null) {
      try {
        final course = _courses.firstWhere((c) => c.id == _selectedCourseId);
        return '${course.name} (${course.code})';
      } catch (e) {
        return courseIdController.text;
      }
    }
    return courseIdController.text;
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
              if (_courses.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: const InputDecoration(
                    labelText: "Select Course",
                    border: OutlineInputBorder(),
                  ),
                  items: _courses.map((course) {
                    return DropdownMenuItem(
                      value: course.id,
                      child: Text('${course.name} (${course.code})'),
                    );
                  }).toList(),
                  onChanged: (courseId) {
                    setState(() {
                      _selectedCourseId = courseId;
                      courseIdController.text = courseId ?? '';
                      _selectedStudentId = null;
                      _students.clear();
                    });
                    if (courseId != null) {
                      _loadStudentsForCourse(courseId);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a course';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_courses.isEmpty)
                TextFormField(
                  controller: courseIdController,
                  decoration: const InputDecoration(
                    labelText: "Course ID",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter course ID';
                    }
                    return null;
                  },
                ),
              if (_students.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: "Select Student",
                    border: OutlineInputBorder(),
                  ),
                  items: _students.map((student) {
                    return DropdownMenuItem(
                      value: student.id,
                      child: Text('${student.name} (${student.email})'),
                    );
                  }).toList(),
                  onChanged: (studentId) {
                    setState(() {
                      _selectedStudentId = studentId;
                      studentIdController.text = studentId ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a student';
                    }
                    return null;
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: "Student ID",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student ID';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: examTypeController,
                decoration: const InputDecoration(
                  labelText: "Exam Type",
                  border: OutlineInputBorder(),
                  hintText: "e.g., Midterm, Final, Assignment",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exam type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: marksController,
                      decoration: const InputDecoration(
                        labelText: "Marks Obtained",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter marks';
                        }
                        final marks = double.tryParse(value);
                        if (marks == null) {
                          return 'Please enter valid marks';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: maxMarksController,
                      decoration: const InputDecoration(
                        labelText: "Maximum Marks",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter max marks';
                        }
                        final maxMarks = double.tryParse(value);
                        if (maxMarks == null || maxMarks <= 0) {
                          return 'Please enter valid max marks';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(
                  labelText: "Remarks (Optional)",
                  border: OutlineInputBorder(),
                  hintText: "Any additional comments",
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_shouldShowPreview())
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.preview,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Preview",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPreviewRow("Student", _getStudentName()),
                        _buildPreviewRow("Course", _getCourseName()),
                        _buildPreviewRow(
                            "Exam", examTypeController.text),
                        _buildPreviewRow(
                            "Marks",
                            "${marksController.text} / ${maxMarksController.text}"),
                        if (remarksController.text.isNotEmpty)
                          _buildPreviewRow(
                              "Remarks", remarksController.text),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Upload Result",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
