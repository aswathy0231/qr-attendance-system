import 'package:flutter/material.dart';

import '../models/student_model.dart';

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

      // Top navigation bar
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

        // Edit button
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit),
          ),
        ],
      ),

      // Allows the profile page to scroll
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
            // STUDENT INFORMATION CARD
            // ==================================================

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

                  // Register number
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

                  // Class
                  _profileRow(
                    'Class',
                    student.classId.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // LOGOUT BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed: () {
                  // Returns to the previous screen
                  Navigator.pop(context);
                },

                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),

                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
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
        children: [

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,

              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}