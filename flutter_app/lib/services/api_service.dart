import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/attendance_model.dart';
import '../models/student_model.dart';

class ApiService {
  // Django backend
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // STUDENT LOGIN
  // ============================================================

  Future<Map<String, dynamic>> studentLogin({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(
          data['error'] ?? 'Invalid username or password.',
        );
      }
    } catch (e) {
      throw Exception('Could not connect to the server.');
    }
  }

  // ============================================================
  // GET ALL STUDENTS
  // ============================================================

  Future<List<StudentModel>> getStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/students/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .map(
              (json) => StudentModel.fromJson(json),
            )
            .toList();
      }

      throw Exception('Failed to load students');
    } catch (e) {
      throw Exception('Could not load students.');
    }
  }

  // ============================================================
  // GET ONE STUDENT BY STUDENT ID
  // ============================================================

  Future<StudentModel> getStudentById({
    required int studentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/students/$studentId/'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return StudentModel.fromJson(data);
      }

      throw Exception('Failed to load student details');
    } catch (e) {
      throw Exception('Could not load student details.');
    }
  }

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  Future<Map<String, dynamic>> markAttendance({
    required int studentId,
    required String qrToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'student_id': studentId,
          'qr_token': qrToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      }

      throw Exception(
        data['error'] ?? 'Failed to mark attendance.',
      );
    } catch (e) {
      throw Exception(
        'Could not mark attendance.',
      );
    }
  }

  // ============================================================
  // GET ATTENDANCE HISTORY
  // ============================================================

  Future<List<AttendanceModel>> getAttendanceHistory({
    required int studentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/attendance/history/?student_id=$studentId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .map(
              (json) => AttendanceModel.fromJson(json),
            )
            .toList();
      }

      throw Exception(
        'Failed to load attendance history',
      );
    } catch (e) {
      throw Exception(
        'Could not load attendance history.',
      );
    }
  }
}