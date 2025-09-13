// import 'models/student.dart';
// import 'models/teacher.dart';
// import 'models/course.dart';
// import 'models/cr.dart';

// void main() {
//   // Test Student
//   var student = Student(
//     id: "S1",
//     name: "Alice",
//     email: "alice@example.com",
//     batch: "2025",
//     branch: "CSE",
//     attendancePercentage: 85.5,
//     spi: 8.2,
//     cpi: 8.0,
//   );
//   print("Student JSON: ${student.toJson()}");

//   // Test Teacher
//   var teacher = Teacher(
//     id: "T1",
//     name: "Dr. Smith",
//     email: "smith@college.edu",
//     coursesTaught: ["CS101", "CS102"],
//   );
//   print("Teacher JSON: ${teacher.toJson()}");

//   // Test Course
//   var course = Course(
//     id: "C1",
//     name: "Object Oriented Programming",
//     code: "CS101",
//     facultyId: teacher.id,
//     studentIds: [student.id],
//   );
//   print("Course JSON: ${course.toJson()}");

//   // Test CR
//   var cr = CR(
//     id: "S2",
//     name: "Bob",
//     email: "bob@example.com",
//     batch: "2025",
//     branch: "CSE",
//     attendancePercentage: 90.0,
//     spi: 8.5,
//     cpi: 8.3,
//   );
//   print("CR JSON: ${cr.toJson()}");
// }
import 'package:flutter/material.dart';
import 'splash_page.dart'; // or 'login_page.dart'
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AcadMate',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
      home: const SplashPage(), // or const LoginPage()
      debugShowCheckedModeBanner: false,
    );
  }
}