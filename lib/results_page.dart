import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';
import 'models/result.dart';
import 'models/course.dart';
import 'dart:collection';
import 'widgets/pdf_viewer.dart'; // Import the PDF Viewer

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  int _selectedSemester = 1;
  final List<int> _semesters = [1, 2, 3, 4, 5, 6, 7, 8];

  // Helper to fetch all courses and map their IDs to semesters
  Future<Map<String, String>> _getCourseSemesterMap() async {
    final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();
    final Map<String, String> courseSemesterMap = {};
    for (var doc in coursesSnapshot.docs) {
      courseSemesterMap[doc.id] = doc.data()['semester'] ?? '0';
    }
    return courseSemesterMap;
  }

  // Function to handle tapping the "View Marksheet" button
  void _viewMarksheet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final url = await FirestoreService.getMarksheetUrl(user.uid, _selectedSemester);

    if (mounted) {
      Navigator.pop(context); // Dismiss the loading indicator
    }

    if (url != null) {
      // Navigate to the PDF Viewer
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              pdfUrl: url,
              title: 'Semester $_selectedSemester Marksheet',
            ),
          ),
        );
      }
    } else {
      // Show an error if no URL is found
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No marksheet found for Semester $_selectedSemester.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results by Semester'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ADDED: "View Marksheet" Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _viewMarksheet,
            tooltip: 'View Marksheet',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSemesterTabs(),
          Expanded(
            child: user == null
                ? const Center(child: Text("Please log in to see results."))
                : FutureBuilder<Map<String, String>>(
              future: _getCourseSemesterMap(),
              builder: (context, courseMapSnapshot) {
                if (courseMapSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (courseMapSnapshot.hasError) {
                  return const Center(child: Text("Error loading course data."));
                }

                final courseSemesterMap = courseMapSnapshot.data ?? {};

                return StreamBuilder<List<Result>>(
                  stream: FirestoreService.getStudentResults(user.uid),
                  builder: (context, resultSnapshot) {
                    if (resultSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (resultSnapshot.hasError) {
                      return Center(child: Text('Error: ${resultSnapshot.error}'));
                    }
                    if (!resultSnapshot.hasData || resultSnapshot.data!.isEmpty) {
                      return const Center(child: Text('No results have been uploaded yet.'));
                    }

                    // Filter results for the selected semester
                    final semesterResults = resultSnapshot.data!.where((result) {
                      final semesterString = courseSemesterMap[result.courseId] ?? '0';
                      return int.tryParse(semesterString) == _selectedSemester;
                    }).toList();

                    if (semesterResults.isEmpty) {
                      return Center(
                        child: Text(
                          'No results found for Semester $_selectedSemester.',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    // Group by course for the expansion tiles
                    final groupedResults = groupBy(semesterResults, (Result result) => result.courseId);
                    final courseIds = groupedResults.keys.toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: courseIds.length,
                      itemBuilder: (context, index) {
                        final courseId = courseIds[index];
                        final results = groupedResults[courseId]!;
                        return _buildCourseCard(context, courseId, results);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _semesters.map((semester) {
            final isSelected = semester == _selectedSemester;
            return GestureDetector(
              onTap: () => setState(() => _selectedSemester = semester),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sem $semester',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, String courseId, List<Result> results) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: _CourseNameWidget(courseId: courseId),
        children: results.map((result) => _buildResultTile(context, result)).toList(),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, Result result) {
    final percentage = (result.marks / result.maxMarks * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  result.examId,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(result.grade),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result.grade,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded: ${DateFormat.yMMMd().format(result.uploadedAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${result.marks.toStringAsFixed(1)} / ${result.maxMarks.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getGradeColor(result.grade)),
              ),
            ],
          ),
          if (result.remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                result.remarks,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green[600]!;
      case 'B+':
      case 'B':
        return Colors.blue[600]!;
      case 'C+':
      case 'C':
        return Colors.orange[600]!;
      default:
        return Colors.red[600]!;
    }
  }
}

class _CourseNameWidget extends StatelessWidget {
  final String courseId;
  const _CourseNameWidget({required this.courseId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Course?>(
      future: FirestoreService.getCourse(courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
        }
        final course = snapshot.data!;
        return Text(
          course.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

Map<K, List<V>> groupBy<K, V>(Iterable<V> iterable, K Function(V) key) {
  var map = <K, List<V>>{};
  for (var element in iterable) {
    (map[key(element)] ??= []).add(element);
  }
  return map;
}