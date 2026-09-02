import 'package:flutter/material.dart';

/// Screen shown after attendance has been successfully marked.
/// Displays a success icon, a summary card with subject/date/time,
/// and a "Done" button that pops back to the first route.
class AttendanceResultScreen extends StatelessWidget {
  final String subject;
  final String date;
  final String time;

  const AttendanceResultScreen({
    super.key,
    required this.subject,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111517),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ----- SUCCESS ICON -----
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

                const SizedBox(height: 30),

                // ----- TITLE -----
                const Text(
                  'Attendance Marked!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // ----- SUBTITLE -----
                const Text(
                  'Your attendance has been recorded successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // ----- ATTENDANCE DETAILS CARD -----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2225),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.book_outlined,
                        'Subject',
                        subject,
                      ),

                      const Divider(
                        color: Colors.grey,
                        height: 30,
                      ),

                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Date',
                        date,
                      ),

                      const Divider(
                        color: Colors.grey,
                        height: 30,
                      ),

                      _buildDetailRow(
                        Icons.access_time_outlined,
                        'Time',
                        time,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ----- DONE BUTTON -----
                // Pops all routes until the first (root) route, returning
                // the user to the starting screen of the app/flow.
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single row inside the details card, showing an [icon],
  /// a small grey [label], and the bold white [value] beneath it.
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        // Leading icon for this detail row.
        Icon(
          icon,
          color: const Color(0xFF1976FF),
        ),

        const SizedBox(width: 15),

        // Label + value stacked vertically, filling remaining width.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
