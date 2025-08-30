import 'user.dart';

class Teacher extends User {
  final List<String> coursesTaught;

  Teacher({
    required String id,
    required String name,
    required String email,
    required this.coursesTaught,
  }) : super(id: id, name: name, email: email, role: "teacher");

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "coursesTaught": coursesTaught,
      };

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      coursesTaught: List<String>.from(json["coursesTaught"]),
    );
  }
}
