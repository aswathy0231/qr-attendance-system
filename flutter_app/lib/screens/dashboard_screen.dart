import 'package:flutter/material.dart';

// Import screens that can be opened from the dashboard
import 'scanner_screen.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final int studentId;

  const DashboardScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic structure of the screen
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // Keeps content safe and allows the page to scroll
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Container(
                height: 155,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1455D1),
                      Color(0xFF2D70E5),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 27,
                    ),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, Aswathy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Good morning!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              // DATE CARD
              Transform.translate(
                offset: const Offset(0, -35),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF175CD3),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Date",
                                style: TextStyle(fontSize: 12),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '21 July 2025',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Monday',
                            style: TextStyle(
                              color: Color(0xFF175CD3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // THREE MAIN CARDS
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      // SCAN QR
                      Expanded(
                        child: _dashboardCard(
                          context,
                          Icons.qr_code_scanner,
                          const Color(0xFF4057E8),
                          'Scan QR',
                          ScannerScreen(
                            studentId: studentId,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ATTENDANCE HISTORY
                      Expanded(
                        child: _dashboardCard(
                          context,
                          Icons.assignment,
                          const Color(0xFF39B66A),
                          'Attendance',
                          AttendanceHistoryScreen(
                            studentId: studentId,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // PROFILE
                      Expanded(
                        child: _dashboardCard(
                          context,
                          Icons.person,
                          const Color(0xFFFF9D2E),
                          'Profile',
                          const ProfileScreen(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // NOTICE
              Transform.translate(
                offset: const Offset(0, -10),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: Color(0xFF175CD3),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Ensure you scan the QR code within the class time.',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),

              // LOGOUT BUTTON
              Transform.translate(
                offset: const Offset(0, -5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable function for creating the three dashboard cards
  Widget _dashboardCard(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'View your\nattendance',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
