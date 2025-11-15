import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'services/firestore_service.dart';
import 'models/notification.dart' as app_notification;

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<String?> _getUserRole(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data()?['role'];
    } catch (e) {
      debugPrint("Error getting user role: $e");
      return 'student'; // Default to student on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("You need to be logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<String?>(
        future: _getUserRole(user.uid),
        builder: (context, roleSnapshot) {
          if (roleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final role = roleSnapshot.data ?? 'student';

          // Show "Sent" for teachers, "Inbox" for students/CRs
          final stream = (role == 'teacher')
              ? FirestoreService.getSentNotifications(user.uid)
              : FirestoreService.getUserNotifications(user.uid);

          final emptyMessage = (role == 'teacher')
              ? "You haven't sent any notifications yet."
              : "You have no notifications yet.";

          return StreamBuilder<List<app_notification.Notification>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(emptyMessage),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.blue[100]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.campaign, color: Colors.blue[800]),
                      ),
                      title: Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notification.message),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat.yMMMd().add_jm().format(notification.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}