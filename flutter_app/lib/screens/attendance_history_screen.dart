import 'package:flutter/material.dart';

import '../models/attendance_model.dart';
import '../services/api_service.dart';

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

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  // API service used to communicate with Django backend.
  final ApiService apiService = ApiService();


  // Stores attendance records received from the backend.
  List<AttendanceModel> attendanceRecords = [];

  // Stores the selected filter.
  String selectedFilter = 'All';

  // Indicates whether attendance data is loading.
  bool isLoading = true;

  // Stores an error message if loading fails.
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    // Load attendance history when the screen opens.
    _loadAttendanceHistory();
  }

  /// Fetches attendance history from the Django backend.
  Future<void> _loadAttendanceHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final records = await apiService.getAttendanceHistory(
        studentId: widget.studentId,
      );

      if (!mounted) return;

      setState(() {
        attendanceRecords = records;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not load attendance history.';
      });
    }
  }

  /// Returns attendance records based on the selected filter.
  List<AttendanceModel> get filteredRecords {
    if (selectedFilter == 'Present') {
      return attendanceRecords
          .where(
            (record) =>
                record.status.toLowerCase() == 'present',
          )
          .toList();
    }

    if (selectedFilter == 'Absent') {
      return attendanceRecords
          .where(
            (record) =>
                record.status.toLowerCase() == 'absent',
          )
          .toList();
    }

    return attendanceRecords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // Top navigation bar.
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

        // Reload attendance history when refresh is pressed.
        actions: [
          IconButton(
            onPressed: _loadAttendanceHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // Filter tabs.
          Row(
            children: [
              Expanded(
                child: _Tab(
                  title: 'All',
                  selected: selectedFilter == 'All',
                  onTap: () {
                    setState(() {
                      selectedFilter = 'All';
                    });
                  },
                ),
              ),

              Expanded(
                child: _Tab(
                  title: 'Present',
                  selected: selectedFilter == 'Present',
                  onTap: () {
                    setState(() {
                      selectedFilter = 'Present';
                    });
                  },
                ),
              ),

              Expanded(
                child: _Tab(
                  title: 'Absent',
                  selected: selectedFilter == 'Absent',
                  onTap: () {
                    setState(() {
                      selectedFilter = 'Absent';
                    });
                  },
                ),
              ),
            ],
          ),

          // Attendance content.
          Expanded(
            child: _buildAttendanceContent(),
          ),
        ],
      ),
    );
  }

  /// Builds loading, error, empty, or attendance list content.
  Widget _buildAttendanceContent() {
    // Loading indicator.
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error message.
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _loadAttendanceHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filtered attendance records.
    final records = filteredRecords;

    // Empty attendance history.
    if (records.isEmpty) {
      return Center(
        child: Text(
          selectedFilter == 'All'
              ? 'No attendance records found.'
              : 'No ${selectedFilter.toLowerCase()} records found.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF667085),
          ),
        ),
      );
    }

    // Attendance record list.
    return RefreshIndicator(
      onRefresh: _loadAttendanceHistory,

      child: ListView.builder(
        padding: const EdgeInsets.all(14),

        itemCount: records.length,

        itemBuilder: (context, index) {
          final record = records[index];

          return AttendanceItem(
            subject: record.subject,
            professor: record.professor,
            date: record.date,
            time: record.time,
            present:
                record.status.toLowerCase() == 'present',
          );
        },
      ),
    );
  }
}


// Reusable widget for filter tabs.
class _Tab extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),

        decoration: BoxDecoration(
          border: Border(
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
            color: selected
                ? const Color(0xFF175CD3)
                : Colors.black,

            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}


// Reusable widget for each attendance record.
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
          // Present / absent icon.
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

          // Subject and professor.
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

          // Date, time and status.
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),

              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),

              const SizedBox(height: 5),

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