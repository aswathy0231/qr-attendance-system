class StudentModel {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String registerNumber;
  final String phone;
  final int classId;

  // Additional academic information
  final String className;
  final int semester;
  final String section;
  final String departmentName;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.registerNumber,
    required this.phone,
    required this.classId,
    required this.className,
    required this.semester,
    required this.section,
    required this.departmentName,
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
      className: json['class_name'] ?? '',
      semester: json['semester'] ?? 0,
      section: json['section'] ?? '',
      departmentName: json['department_name'] ?? '',
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
      'class_name': className,
      'semester': semester,
      'section': section,
      'department_name': departmentName,
    };
  }
}
