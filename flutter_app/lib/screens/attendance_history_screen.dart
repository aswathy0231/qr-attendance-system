import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AttendanceHistoryScreen extends StatefulWidget {
  final int studentId;

  const AttendanceHistoryScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<dynamic> attendanceRecords = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAttendanceHistory();
  }

  Future<void> fetchAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/attendance/history/'
          '?student_id=${widget.studentId}',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          attendanceRecords = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load attendance history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to connect to server';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
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

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : errorMessage != null
                    ? Center(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      )
                    : attendanceRecords.isEmpty
                        ? const Center(
                            child: Text(
                              'No attendance records found',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final record = attendanceRecords[index];

                              final bool present =
                                  record['status']?.toString().toLowerCase() ==
                                      'present';

                              return AttendanceItem(
                                subject: record['subject']?.toString() ?? '',
                                professor:
                                    record['professor']?.toString() ?? '',
                                date: record['date']?.toString() ?? '',
                                time: record['time']?.toString() ?? '',
                                present: present,
                              );
                            },
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
          bottom: BorderSide(
            color: selected ? const Color(0xFF175CD3) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? const Color(0xFF175CD3) : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  present ? const Color(0xFF3DBA70) : const Color(0xFFE84444),
            ),
            child: Icon(
              present ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
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
              Text(
                present ? 'Present' : 'Absent',
                style: TextStyle(
                  fontSize: 10,
                  color: present ? Colors.green : Colors.red,
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
