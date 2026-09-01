/// Represents a student and their profile information.
class StudentModel {
  final int id;
  final String name;
  final String email;
  final String registerNumber;
  final String course;
  final String semester;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.registerNumber,
    required this.course,
    required this.semester,
  });

  /// Creates a StudentModel object from JSON data
  /// received from the Django backend.
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      registerNumber: json['register_number'] ?? '',
      course: json['course'] ?? '',
      semester: json['semester'] ?? '',
    );
  }

  /// Converts the StudentModel object into JSON data.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'register_number': registerNumber,
      'course': course,
      'semester': semester,
    };
  }
}