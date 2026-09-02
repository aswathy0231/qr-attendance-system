import 'dart:convert';

import 'package:http/http.dart' as http;

/// Handles all communication between the Flutter application
/// and the Django backend.
class ApiService {
  // Django backend base URL.
  // Replace this IP address if your computer's local IP changes.
  static const String baseUrl = 'http://192.168.1.55:8000';

  /// Sends the scanned QR token and student ID to the backend
  /// to mark student attendance.
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

      // Decode the backend response.
      final Map<String, dynamic> data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      // Add the HTTP status code so the UI can check the result.
      data['statusCode'] = response.statusCode;

      return data;
    } catch (e) {
      // Return a consistent error response if the server
      // cannot be reached.
      return {
        'statusCode': 0,
        'error': 'Could not connect to the server.',
      };
    }
  }
}