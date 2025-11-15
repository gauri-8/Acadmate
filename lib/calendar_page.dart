import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:collection';

import 'models/event.dart';
import 'services/firestore_service.dart';
import 'create_event_page.dart';

// Helper function
int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // State for managing events
  late Stream<List<Event>> _eventStream;
  LinkedHashMap<DateTime, List<Event>> _events = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  );
  List<Event> _selectedEvents = [];

  String? _userRole;
  String? _currentUserId; // To check who created the event

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventStream = FirestoreService.getCalendarEvents();
    _loadEvents();
    _fetchUser(); // Fetch user's role and ID
  }

  Future<void> _fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _currentUserId = user.uid; // Store the user's ID
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userRole = doc.data()?['role'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }

  void _loadEvents() {
    _eventStream.listen((eventList) {
      final newEvents = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );

      for (final event in eventList) {
        final dateKey = DateTime.utc(event.date.year, event.date.month, event.date.day);
        if (newEvents[dateKey] == null) {
          newEvents[dateKey] = [];
        }
        newEvents[dateKey]!.add(event);
      }

      if (mounted) {
        setState(() {
          _events = newEvents;
          _onDaySelected(_selectedDay!, _focusedDay);
        });
      }
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedSelectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _events[normalizedSelectedDay] ?? [];
    });
  }

  // --- Delete Event Logic ---
  Future<void> _deleteEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService.deleteEvent(eventId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canCreateEvent = _userRole == 'teacher' || _userRole == 'admin' || _userRole == 'cr';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final normalizedDay = DateTime.utc(day.year, day.month, day.day);
              return _events[normalizedDay] ?? [];
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20.0),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.black),
              formatButtonShowsNext: false,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue[200],
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[400],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: canCreateEvent
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEventPage(
                selectedDay: _selectedDay ?? DateTime.now(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No events for this day.',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        // Check if the current user is the one who created the event
        bool canEdit = event.createdBy == _currentUserId;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getEventColor(event.type),
              child: Icon(_getEventIcon(event.type), color: Colors.white),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: event.description.isNotEmpty ? Text(event.description) : null,
            // --- ADDED EDIT/DELETE BUTTONS ---
            trailing: canEdit
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit Event',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Navigate to CreateEventPage in "Edit Mode"
                        builder: (context) => CreateEventPage(event: event),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  tooltip: 'Delete Event',
                  onPressed: () => _deleteEvent(event.id),
                ),
              ],
            )
                : null, // No buttons if user didn't create it
          ),
        );
      },
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'exam':
        return Colors.red[400]!;
      case 'class':
        return Colors.blue[400]!;
      case 'holiday':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'exam':
        return Icons.assignment;
      case 'class':
        return Icons.book;
      case 'holiday':
        return Icons.beach_access;
      default:
        return Icons.event;
    }
  }
}