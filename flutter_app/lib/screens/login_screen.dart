import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/student_model.dart';
import '../services/api_service.dart';

import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController studentIdController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  // Django backend
  static const String baseUrl = 'http://127.0.0.1:8000';

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // STUDENT LOGIN
  // ============================================================

  Future<void> studentLogin() async {
    final username = studentIdController.text.trim();
    final password = passwordController.text;

    // Empty field validation
    if (username.isEmpty) {
      _showError('Please enter your Student ID.');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

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

      if (!mounted) return;

      final data = jsonDecode(response.body);

      print('LOGIN RESPONSE: $data');

      if (response.statusCode == 200) {
        // Make sure this login belongs to a student.
        if (data['role'] != 'student') {
          setState(() {
            isLoading = false;
          });

          _showError(
            'This account is not a student account.',
          );

          return;
        }

        // Get the logged-in student's actual student_id.
        final int studentId = data['student_id'];

        print('Student ID: $studentId');

        // Create API service
        final apiService = ApiService();

        // Fetch the student's actual details from the database.
        final StudentModel student = await apiService.getStudentById(
          studentId: studentId,
        );

        if (!mounted) return;

        print('Student Name: ${student.name}');
        print('Student Email: ${student.email}');
        print('Register Number: ${student.registerNumber}');

        setState(() {
          isLoading = false;
        });

        // Open dashboard with the actual student details.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              student: student,
            ),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });

        _showError(
          data['error'] ?? 'Invalid username or password.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print('LOGIN ERROR: $e');

      _showError(
        'Could not connect to the server.',
      );
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                height: 170,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1558D6),
                      Color(0xFF2872E8),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(45),
                    bottomRight: Radius.circular(45),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 50,
                      color: Color(0xFF151A2D),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Student Login',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Sign in to continue',
                style: TextStyle(
                  color: Color(0xFF667085),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // LOGIN FORM
              // ==================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                ),
                child: Column(
                  children: [
                    // ==================================================
                    // STUDENT ID
                    // ==================================================

                    TextField(
                      controller: studentIdController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                        ),
                        hintText: 'Student ID',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextField(
                      controller: passwordController,
                      enabled: !isLoading,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                _showError(
                                  'Please contact Admin to reset your password.',
                                );
                              },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF175CD3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : studentLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF175CD3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // ACCOUNT INFORMATION
                    // ==================================================

                    const Text(
                      "Don't have an account? Contact Admin",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
