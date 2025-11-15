import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:acadmate/models/course.dart';
import 'package:acadmate/models/user.dart' as local_user;
import 'package:acadmate/services/firestore_service.dart';
import 'package:acadmate/models/attendance.dart'; // <-- 1. IMPORT THE NEW MODEL

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

  // --- UPDATED: Use the new service function and model ---
  Future<void> _loadAttendanceForDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      // Use the new service function
      final AttendanceRecord? record = await FirestoreService.getAttendanceRecord(widget.course.id, date);

      if (record != null) {
        // If a record exists, load its statuses
        setState(() {
          _attendanceStatus = record.statuses;
        });
      } else {
        // If no record exists, default all to 'present'
        setState(() {
          // Ensure all students from the course list are in the map
          final newStatusMap = { for (var s in _students) s.id : 'present' };
          _attendanceStatus = newStatusMap;
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

  // --- UPDATED: Use the new service function and model ---
  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    try {
      // 1. Create the date string to use as the Document ID
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 2. Create an instance of our new model
      final attendanceRecord = AttendanceRecord(
        id: dateString,
        date: _selectedDate,
        statuses: _attendanceStatus,
      );

      // 3. Pass the model to the service function
      await FirestoreService.saveAttendance(
        widget.course.id,
        attendanceRecord,
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
              ? const SizedBox( // Show a small spinner when saving
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
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
    // Ensure every student has a status, default to 'present'
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
                // Ensure the student ID exists in the map before updating
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