import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool isLoading = false;
  bool sessionActive = false;

  String? qrImage;
  String? qrToken;
  String? errorMessage;

  int? sessionId;

  // Current test assignment
  final int assignmentId = 3;

  Future<void> startAttendance() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/attendance/sessions/create/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'assignment_id': assignmentId,
          'duration_minutes': 10,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        setState(() {
          sessionId = data['session_id'];
          qrToken = data['qr_token'];
          qrImage = data['qr_image'];
          sessionActive = true;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to start attendance (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not connect to the server.';
        isLoading = false;
      });
    }
  }

  Future<void> endAttendance() async {
    if (sessionId == null) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/attendance/sessions/end/',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          sessionActive = false;
          qrImage = null;
          qrToken = null;
          sessionId = null;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance session ended'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Failed to end attendance';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Could not connect to the server.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF175CD3),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              const Text(
                'Hello, Teacher One',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Manage your attendance sessions',
                style: TextStyle(
                  color: Color(0xFF667085),
                ),
              ),

              const SizedBox(height: 25),

              // Subject information card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: Color(0xFF175CD3),
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Current Class',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Python',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MCA • Semester 1',
                      style: TextStyle(
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Assignment ID: 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF98A2B3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Start attendance button
              if (!sessionActive)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : startAttendance,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_2),
                    label: Text(
                      isLoading ? 'Starting Attendance...' : 'Start Attendance',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF175CD3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              // Error message
              if (errorMessage != null) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],

              // Active session
              if (sessionActive) ...[
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Attendance Session Active',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Session ID: $sessionId',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // QR image
                      if (qrImage != null)
                        Image.memory(
                          base64Decode(
                            qrImage!.split(',').last,
                          ),
                          width: 260,
                          height: 260,
                        ),

                      const SizedBox(height: 15),

                      const Text(
                        'Students can scan this QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667085),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // End attendance
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: isLoading ? null : endAttendance,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.stop_circle_outlined,
                                ),
                          label: Text(
                            isLoading
                                ? 'Ending Attendance...'
                                : 'End Attendance',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(
                              color: Colors.red.shade700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
