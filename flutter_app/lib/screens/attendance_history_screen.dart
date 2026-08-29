import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // Top navigation bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF175CD3),
        foregroundColor: Colors.white,

        title: const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      body: Column(
        children: [

          // Filter tabs
          const Row(
            children: [

              Expanded(
                child: _Tab(
                  title: 'All',
                  selected: true,
                ),
              ),

              Expanded(
                child: _Tab(
                  title: 'Present',
                  selected: false,
                ),
              ),

              Expanded(
                child: _Tab(
                  title: 'Absent',
                  selected: false,
                ),
              ),
            ],
          ),

          // Takes the remaining screen space for the list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),

              // Attendance records
              children: const [

                AttendanceItem(
                  subject: 'Operating System',
                  professor: 'Prof. Ramesh',
                  date: '21 July 2025',
                  time: '9:00 AM',
                  present: true,
                ),

                AttendanceItem(
                  subject: 'Java Programming',
                  professor: 'Prof. Anitha',
                  date: '18 July 2025',
                  time: '10:30 AM',
                  present: false,
                ),

                AttendanceItem(
                  subject: 'Database Management',
                  professor: 'Prof. Ramesh',
                  date: '17 July 2025',
                  time: '2:00 PM',
                  present: true,
                ),

                AttendanceItem(
                  subject: 'Web Technologies',
                  professor: 'Prof. Anitha',
                  date: '16 July 2025',
                  time: '11:00 AM',
                  present: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Reusable widget for the filter tabs
class _Tab extends StatelessWidget {
  final String title;
  final bool selected;

  const _Tab({
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),

      decoration: BoxDecoration(
        border: Border(
          // Shows blue underline only for selected tab
          bottom: BorderSide(
            color: selected
                ? const Color(0xFF175CD3)
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),

      child: Text(
        title,
        textAlign: TextAlign.center,

        style: TextStyle(
          // Changes color based on selected value
          color: selected
              ? const Color(0xFF175CD3)
              : Colors.black,

          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}


// Reusable widget for each attendance record
class AttendanceItem extends StatelessWidget {
  final String subject;
  final String professor;
  final String date;
  final String time;
  final bool present;

  const AttendanceItem({
    super.key,
    required this.subject,
    required this.professor,
    required this.date,
    required this.time,
    required this.present,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        children: [

          // Shows check for Present and X for Absent
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: present
                  ? const Color(0xFF3DBA70)
                  : const Color(0xFFE84444),
            ),

            child: Icon(
              present
                  ? Icons.check
                  : Icons.close,

              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Subject and professor information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  professor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),

          // Date, time and attendance status
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [

              Text(
                date,
                style: const TextStyle(fontSize: 10),
              ),

              Text(
                time,
                style: const TextStyle(fontSize: 10),
              ),

              const SizedBox(height: 5),

              // Displays Present or Absent
              Text(
                present
                    ? 'Present'
                    : 'Absent',

                style: TextStyle(
                  fontSize: 10,

                  color: present
                      ? Colors.green
                      : Colors.red,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}