class Course {
  final String id;
  final String name;
  final String code;
  final String facultyId;
  final List<String> studentIds;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyId,
    required this.studentIds,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "code": code,
        "facultyId": facultyId,
        "studentIds": studentIds,
      };

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json["id"],
      name: json["name"],
      code: json["code"],
      facultyId: json["facultyId"],
      studentIds: List<String>.from(json["studentIds"]),
    );
  }
}
