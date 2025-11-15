class Course {
  final String id;
  final String name;
  final String code;
  final String facultyId;
  final List<String> studentIds;
  final String semester; // Added field
  final String academicYear; // Added field

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyId,
    required this.studentIds,
    required this.semester,
    required this.academicYear,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "code": code,
    "facultyId": facultyId,
    "studentIds": studentIds,
    "semester": semester,
    "academicYear": academicYear,
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json["id"] ?? '',
      name: json["name"] ?? 'Unnamed Course',
      code: json["code"] ?? 'N/A',
      facultyId: json["facultyId"] ?? '',
      studentIds: List<String>.from(json["studentIds"] ?? []),
      semester: json["semester"] ?? 'Unknown Semester', // Added with fallback
      academicYear: json["academicYear"] ?? 'N/A', // Added with fallback
    );
  }
}