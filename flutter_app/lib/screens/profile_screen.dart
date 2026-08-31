import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

        // Buttons placed on the right side of AppBar
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

            // Profile icon
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

            const Text(
              'Aswathy A',
              style: TextStyle(
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

            // Student information card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                children: [

                  // Reusable rows for student information
                  _profileRow(
                    'Student ID',
                    'TKMCA23M001',
                  ),

                  _profileRow(
                    'Email',
                    'aswathy.a@tkmce.ac.in',
                  ),

                  _profileRow(
                    'Department',
                    'Master of Computer Applications',
                  ),

                  _profileRow(
                    'Semester',
                    'II Semester',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Logout button
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

  // Reusable function for displaying profile information
  Widget _profileRow(
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),

      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),

      // Displays title and value side by side
      child: Row(
        children: [

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}