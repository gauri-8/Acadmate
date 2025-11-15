import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/academic_profile.dart';
import 'services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // Separate futures to fetch user data and academic profile
  late Future<DocumentSnapshot> _userFuture;
  late Future<AcademicProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    _userFuture = FirebaseFirestore.instance.collection("users").doc(widget.userId).get();
    _profileFuture = FirestoreService.getAcademicProfile(widget.userId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Only update the name in the main user document
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .update({'name': _nameController.text.trim()});

      setState(() {
        _isEditing = false;
        // Refresh the data after saving
        _loadProfileData();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully! ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startEditing(Map<String, dynamic> userData) {
    _nameController.text = userData['name'] ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_userFuture, _profileFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final userDoc = snapshot.data![0] as DocumentSnapshot;
          final academicProfile = snapshot.data![1] as AcademicProfile?;

          if (!userDoc.exists) {
            return const Center(child: Text("Profile Not Found"));
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final role = userData['role'] ?? 'student';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(userData),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Personal Information", Icons.person),
                          const SizedBox(height: 20),
                          _buildInfoField(
                            label: "Full Name",
                            value: userData['name'] ?? 'Not set',
                            controller: _nameController,
                            isEditable: _isEditing,
                            icon: Icons.badge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoField(
                            label: "Email",
                            value: userData['email'] ?? 'Not set',
                            isEditable: false,
                            icon: Icons.email,
                          ),
                          if (role == 'student' && academicProfile != null) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader("Academic Information", Icons.school),
                            const SizedBox(height: 20),
                            _buildInfoField(
                              label: "Current Semester",
                              value: academicProfile.semester,
                              isEditable: false,
                              icon: Icons.calendar_today,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoField(
                              label: "SPI (Semester Performance Index)",
                              value: academicProfile.spi.toStringAsFixed(2),
                              isEditable: false,
                              icon: Icons.trending_up,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoField(
                              label: "CPI (Cumulative Performance Index)",
                              value: academicProfile.cpi.toStringAsFixed(2),
                              isEditable: false,
                              icon: Icons.analytics,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoField(
                              label: "Attendance",
                              value: "${academicProfile.attendancePercentage.toStringAsFixed(1)}%",
                              isEditable: false,
                              icon: Icons.check_circle_outline,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(userData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                (data['name'] ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[600]),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data['name'] ?? 'Unknown User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              data['email'] ?? 'No email',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (data['role'] ?? 'student').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[600]),
        ),
      ],
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    TextEditingController? controller,
    required bool isEditable,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isEditable && controller != null)
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: value == 'Not set' ? 'Enter $label' : value,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (val) => val!.isEmpty ? 'This field cannot be empty' : null,
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: value == 'Not set' ? Colors.grey[500] : Colors.black87),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> userData) {
    // Only the user themselves can edit their own profile
    bool canEdit = FirebaseAuth.instance.currentUser?.uid == widget.userId;

    if (!canEdit) {
      return const SizedBox.shrink(); // Return an empty widget if the user can't edit
    }

    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isLoading ? "Saving..." : "Save Changes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _cancelEditing,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _startEditing(userData),
          icon: const Icon(Icons.edit),
          label: const Text("Edit Profile"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
  }
}