class StudentModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String registerNumber;
  final String phone;
  final int classId;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.registerNumber,
    required this.phone,
    required this.classId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['student_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      registerNumber: json['register_no'] ?? '',
      phone: json['phone'] ?? '',
      classId: json['class_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': id,
      'user_id': userId,
      'full_name': name,
      'email': email,
      'register_no': registerNumber,
      'phone': phone,
      'class_id': classId,
    };
  }
}