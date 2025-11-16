import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'models/course.dart';
import 'models/course_material.dart';
import 'services/firestore_service.dart';

class CourseMaterialsPage extends StatefulWidget {
  final Course course;
  const CourseMaterialsPage({super.key, required this.course});

  @override
  State<CourseMaterialsPage> createState() => _CourseMaterialsPageState();
}

class _CourseMaterialsPageState extends State<CourseMaterialsPage> {
  String? _userRole;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = doc.data()?['role'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;
    String fileType = result.files.single.extension ?? 'file';

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // 1. Upload file to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('course_materials/${widget.course.id}/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Create CourseMaterial object
      final material = CourseMaterial(
        id: '', // Will be set by Firestore
        title: fileName,
        fileUrl: downloadUrl,
        fileName: fileName,
        fileType: fileType,
        uploadedBy: user.uid,
        uploadedAt: DateTime.now(),
      );

      // 3. Save metadata to Firestore
      await FirestoreService.addCourseMaterial(widget.course.id, material);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the file.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteMaterial(CourseMaterial material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete from Firestore first. This removes it from the UI.
      await FirestoreService.deleteCourseMaterial(widget.course.id, material.id);

      // 2. Try to delete from Firebase Storage.
      try {
        await FirebaseStorage.instance.refFromURL(material.fileUrl).delete();
      } on FirebaseException catch (e) {
        // If the error is "object-not-found", we can ignore it.
        // The file is already gone, which is what we wanted.
        if (e.code == 'object-not-found') {
          debugPrint("File already deleted from storage.");
        } else {
          // If it's a different error (like permissions), re-throw it.
          throw e;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting material: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canUpload = _userRole == 'teacher' || _userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.code} Materials'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_isUploading) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<CourseMaterial>>(
              stream: FirestoreService.getCourseMaterials(widget.course.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No materials have been uploaded for this course.'),
                  );
                }

                final materials = snapshot.data!;
                return ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Icon(_getIconForType(material.fileType), color: Theme.of(context).primaryColor),
                        title: Text(material.title),
                        subtitle: Text('Type: ${material.fileType.toUpperCase()}'),
                        onTap: () => _openFile(material.fileUrl),
                        trailing: canUpload
                            ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteMaterial(material),
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canUpload && !_isUploading
          ? FloatingActionButton(
        onPressed: _pickAndUploadFile,
        tooltip: 'Upload File',
        child: const Icon(Icons.upload_file),
      )
          : null,
    );
  }

  IconData _getIconForType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'png':
      case 'jpeg':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }
}