import 'user.dart';

class Student extends User {
  final String batch;
  final String branch;
  final double attendancePercentage;
  final double spi;
  final double cpi;

  Student({
    required String id,
    required String name,
    required String email,
    required this.batch,
    required this.branch,
    required this.attendancePercentage,
    required this.spi,
    required this.cpi,
  }) : super(id: id, name: name, email: email, role: "student");

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "batch": batch,
        "branch": branch,
        "attendancePercentage": attendancePercentage,
        "spi": spi,
        "cpi": cpi,
      };

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      batch: json["batch"],
      branch: json["branch"],
      attendancePercentage: json["attendancePercentage"],
      spi: json["spi"],
      cpi: json["cpi"],
    );
  }
}
