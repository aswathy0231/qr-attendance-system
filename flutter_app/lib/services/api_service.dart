import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Invalid username or password.');
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
      final response = await http.get(Uri.parse('$baseUrl/api/students/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((json) => StudentModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load students');
    } catch (e) {
      throw Exception('Could not load students.');
    }
  }

  // ============================================================
  // GET ONE STUDENT BY STUDENT ID
  // ============================================================

  Future<StudentModel> getStudentById({required int studentId}) async {
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId, 'qr_token': qrToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      }

      throw Exception(data['error'] ?? 'Failed to mark attendance.');
    } catch (e) {
      throw Exception('Could not mark attendance.');
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
          '$baseUrl/api/attendance/history/'
          '?student_id=$studentId',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((json) => AttendanceModel.fromJson(json)).toList();
      }

      throw Exception('Failed to load attendance history');
    } catch (e) {
      throw Exception('Could not load attendance history.');
    }
  }

  // ============================================================
  // FACE REGISTRATION
  // ============================================================

  Future<Map<String, dynamic>> registerFace({
    required File imageFile,
    required String accessToken,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/attendance/face/register/'),
      );

      // JWT authentication
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add face image
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      }

      print(
        'FACE REGISTER STATUS: '
        '${response.statusCode}',
      );

      print('FACE REGISTER RESPONSE: $data');

      throw Exception(data['error'] ?? 'Face registration failed.');
    } catch (e) {
      print('FACE REGISTER ERROR: $e');

      throw Exception('Could not register face.');
    }
  }

  // ============================================================
  // DEVICE REGISTRATION
  // ============================================================

  Future<Map<String, dynamic>> registerDevice({
    required String deviceUuid,
    required String deviceName,
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/device/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'device_uuid': deviceUuid,
          'device_name': deviceName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      }

      throw Exception(data['error'] ?? 'Device registration failed.');
    } catch (e) {
      throw Exception('Could not register device.');
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'new_password': newPassword}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      }

      throw Exception(data['error'] ?? 'Password change failed.');
    } catch (e) {
      throw Exception('Could not change password.');
    }
  }
}
