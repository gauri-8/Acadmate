import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadResultPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController examTypeController = TextEditingController();
  final TextEditingController marksController = TextEditingController();

  UploadResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Result")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: studentIdController, decoration: const InputDecoration(labelText: "Student ID")),
              TextFormField(controller: courseIdController, decoration: const InputDecoration(labelText: "Course ID")),
              TextFormField(controller: examTypeController, decoration: const InputDecoration(labelText: "Exam Type")),
              TextFormField(controller: marksController, decoration: const InputDecoration(labelText: "Marks")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("results").add({
                    "studentId": studentIdController.text,
                    "courseId": courseIdController.text,
                    "examType": examTypeController.text,
                    "marks": double.parse(marksController.text),
                    "uploadedAt": DateTime.now(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Result uploaded ✅")));
                },
                child: const Text("Submit"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
