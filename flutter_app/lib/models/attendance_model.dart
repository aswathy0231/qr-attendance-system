/// Represents one attendance record received from the backend.
class AttendanceModel {
  final String subject;
  final String professor;
  final String date;
  final String time;
  final String status;

  AttendanceModel({
    required this.subject,
    required this.professor,
    required this.date,
    required this.time,
    required this.status,
  });

  /// Creates an AttendanceModel object from JSON data
  /// received from the Django backend.
  factory AttendanceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceModel(
      subject: json['subject']?.toString() ?? '',
      professor: json['professor']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  /// Converts the AttendanceModel object to JSON.
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'professor': professor,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}
