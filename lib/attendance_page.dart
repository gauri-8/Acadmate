import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:acadmate/models/course.dart';
import 'package:acadmate/models/user.dart' as local_user;
import 'package:acadmate/services/firestore_service.dart';

class AttendancePage extends StatefulWidget {
  final Course course;

  const AttendancePage({super.key, required this.course});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<local_user.User> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  // A map to keep track of attendance status
  // Key: studentId, Value: "present" | "absent"
  Map<String, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await FirestoreService.getStudentsByCourse(widget.course.id);
      // Initialize all students as 'present' by default
      final statusMap = { for (var s in students) s.id : 'present' };

      setState(() {
        _students = students;
        _attendanceStatus = statusMap;
        _isLoading = false;
      });

      // After loading students, check if attendance for today already exists
      _loadAttendanceForDate(_selectedDate);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- NEW: Function to load existing attendance data ---
  Future<void> _loadAttendanceForDate(DateTime date) async {
    setState(() => _isLoading = true);
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .collection('attendance')
          .doc(dateString)
          .get();

      if (doc.exists && doc.data()?['statuses'] != null) {
        final loadedStatuses = Map<String, String>.from(doc.data()!['statuses']);
        setState(() {
          _attendanceStatus = loadedStatuses;
        });
      } else {
        // If no record exists, default all to 'present'
        setState(() {
          _attendanceStatus = { for (var s in _students) s.id : 'present' };
        });
      }
    } catch (e) {
      debugPrint("Error loading attendance: $e");
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UPDATED: Save attendance function ---
  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      await FirestoreService.saveAttendance(
        widget.course.id,
        _selectedDate,
        _attendanceStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance Saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance - ${widget.course.code}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildDatePicker(),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return _buildStudentTile(student);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAttendance,
          child: _isSaving
              ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
              : const Text('Save Attendance'),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat.yMMMMd().format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                  _loadAttendanceForDate(pickedDate); // Load data for the new date
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(local_user.User student) {
    final status = _attendanceStatus[student.id] ?? 'present';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(student.name.isNotEmpty ? student.name[0] : 'U'),
          ),
          title: Text(student.name),
          subtitle: Text(student.email),
          trailing: ToggleButtons(
            isSelected: [status == 'present', status == 'absent'],
            onPressed: (index) {
              setState(() {
                _attendanceStatus[student.id] = (index == 0) ? 'present' : 'absent';
              });
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: (status == 'present') ? Colors.green[400] : Colors.red[400],
            color: Colors.grey[600],
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Present')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Absent')),
            ],
          ),
        ),
      ),
    );
  }
}