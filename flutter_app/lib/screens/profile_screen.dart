import 'package:flutter/material.dart';

import '../models/student_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final StudentModel student;

  const ProfileScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF175CD3),
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // ==================================================
            // PROFILE ICON
            // ==================================================

            Container(
              width: 95,
              height: 95,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDDE8FF),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Color(0xFF151A2D),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // STUDENT NAME
            // ==================================================

            Text(
              student.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            const Text(
              'Student',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // PERSONAL INFORMATION
            // ==================================================

            _sectionTitle('Personal Information'),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Student ID
                  _profileRow(
                    'Student ID',
                    student.registerNumber,
                  ),

                  // Email
                  _profileRow(
                    'Email',
                    student.email,
                  ),

                  // Phone
                  _profileRow(
                    'Phone',
                    student.phone,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ACADEMIC INFORMATION
            // ==================================================

            _sectionTitle('Academic Information'),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Department
                  _profileRow(
                    'Department',
                    student.departmentName,
                  ),

                  // Semester
                  _profileRow(
                    'Semester',
                    student.semester.toString(),
                  ),

                  // Class
                  _profileRow(
                    'Class',
                    student.className,
                  ),

                  // Section
                  _profileRow(
                    'Section',
                    student.section,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // LOGOUT BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF151A2D),
        ),
      ),
    );
  }

  // ============================================================
  // REUSABLE PROFILE ROW
  // ============================================================

  Widget _profileRow(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
