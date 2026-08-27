import 'package:flutter/material.dart';

// Import screens that can be opened from the dashboard
import 'scanner_screen.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

                // Row arranges the menu, greeting and notification horizontally
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 27,
                    ),

                    const SizedBox(width: 20),

                    // Expanded takes the remaining space in the Row
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
              // Moves the card upward so it overlaps the header
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
                          color: Colors.black.withOpacity(0.06),
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                            color: const Color(0xFFEAF1FF),
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

                  // Row places the three cards side by side
                  child: Row(
                    children: [

                      Expanded(
                        child: _dashboardCard(
                          context,
                          Icons.qr_code_scanner,
                          const Color(0xFF4057E8),
                          'Scan QR',
                          const ScannerScreen(),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _dashboardCard(
                          context,
                          Icons.assignment,
                          const Color(0xFF39B66A),
                          'Attendance',
                          const AttendanceHistoryScreen(),
                        ),
                      ),

                      const SizedBox(width: 10),

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

    // Detects when the user taps the card
    return GestureDetector(
      onTap: () {

        // Opens the selected screen
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
              color: Colors.black.withOpacity(0.04),
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