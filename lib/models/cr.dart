import 'student.dart';

class CR extends Student {
  final bool canMakeAnnouncements;

  CR({
    required String id,
    required String name,
    required String email,
    required String batch,
    required String branch,
    required double attendancePercentage,
    required double spi,
    required double cpi,
    this.canMakeAnnouncements = true,
  }) : super(
          id: id,
          name: name,
          email: email,
          batch: batch,
          branch: branch,
          attendancePercentage: attendancePercentage,
          spi: spi,
          cpi: cpi,
        );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        "canMakeAnnouncements": canMakeAnnouncements,
      };

  factory CR.fromJson(Map<String, dynamic> json) {
    return CR(
      id: json["id"],
      name: json["name"],
      email: json["email"],
      batch: json["batch"],
      branch: json["branch"],
      attendancePercentage: json["attendancePercentage"],
      spi: json["spi"],
      cpi: json["cpi"],
      canMakeAnnouncements: json["canMakeAnnouncements"] ?? true,
    );
  }
}
