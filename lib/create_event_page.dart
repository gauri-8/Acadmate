import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models/event.dart'; // Import the Event model
import 'services/firestore_service.dart'; // Import the service

class CreateEventPage extends StatefulWidget {
  // If an event is passed, this page will edit it.
  // If selectedDay is passed, it's a new event on that day.
  final Event? event;
  final DateTime? selectedDay;

  const CreateEventPage({super.key, this.event, this.selectedDay})
      : assert(event != null || selectedDay != null); // Must have one

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _eventType = 'class';
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Pre-fill fields if we are editing an existing event
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _eventType = event.type;
      _selectedDate = event.date;
      _selectedTime = TimeOfDay.fromDateTime(event.date);
    } else {
      // Otherwise, set defaults for a new event
      _selectedDate = widget.selectedDay!;
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Combine date and time
      final finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create the event data map
      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': Timestamp.fromDate(finalDateTime),
        'type': _eventType,
        'createdBy': user.uid,
        'targetRoles': ['student', 'teacher', 'cr'],
      };

      if (_isEditing) {
        // Update existing event
        await FirestoreService.updateEvent(widget.event!.id, eventData);
      } else {
        // Add new event
        await FirebaseFirestore.instance.collection('events').add(eventData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event ${_isEditing ? "updated" : "created"} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create New Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
              validator: (value) =>
              value!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: const [
                DropdownMenuItem(value: 'class', child: Text('Class')),
                DropdownMenuItem(value: 'exam', child: Text('Exam')),
                DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                DropdownMenuItem(value: 'general', child: Text('General Event')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _eventType = value);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time: ${_selectedTime.format(context)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _pickTime,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitEvent,
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text(_isEditing ? 'Update Event' : 'Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}