/// Represents one attendance record received from the backend.
class AttendanceModel {
  final String subject;
  final String date;
  final String time;
  final String status;

  AttendanceModel({
    required this.subject,
    required this.date,
    required this.time,
    required this.status,
  });

  /// Creates an AttendanceModel object from JSON data
  /// received from the Django backend.
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      subject: json['subject'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
    );
  }

  /// Converts the AttendanceModel object to JSON.
  /// This can be useful when sending attendance data if needed later.
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'date': date,
      'time': time,
      'status': status,
    };
  }
}