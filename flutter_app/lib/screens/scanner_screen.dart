import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import 'attendance_result_screen.dart';

/// Screen that opens the device camera, scans a QR code, and submits it
/// to the backend to mark the student's attendance.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controller for the QR scanner.
  final MobileScannerController scannerController = MobileScannerController();

  // Service used to communicate with the Django backend.
  final ApiService apiService = ApiService();

  // Prevents the same QR from being processed multiple times.
  bool hasScanned = false;

  // Indicates whether the scanned QR is currently being validated.
  bool isValidating = false;

  // Temporary student ID for testing.
  // Later this will come from the logged-in student.
  final int studentId = 1;

  /// Sends the scanned QR token and student ID to the backend.
  Future<void> _markAttendance(String qrToken) async {
    // Call the API service instead of directly making
    // the HTTP request from the UI screen.
    final data = await apiService.markAttendance(
      studentId: studentId,
      qrToken: qrToken,
    );

    if (!mounted) return;

    final int statusCode = data['statusCode'] ?? 0;

    // Attendance successfully marked.
    if (statusCode == 200 || statusCode == 201) {
      // Stop the camera scanner.
      await scannerController.stop();

      if (!mounted) return;

      // Navigate to the attendance confirmation screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceResultScreen(
            // These values will come from the Django API response.
            subject: data['subject'] ?? 'Subject',
            date: data['date'] ?? 'Today',
            time: data['time'] ?? 'Now',
          ),
        ),
      );
    } else {
      // Allow the student to scan again.
      setState(() {
        hasScanned = false;
        isValidating = false;
      });

      // Display the backend or connection error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['error'] ??
                data['message'] ??
                'Failed to mark attendance',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Called automatically when the camera detects a barcode or QR code.
  void _onDetect(BarcodeCapture capture) {
    // Ignore new detections while a previous QR is being processed.
    if (hasScanned) return;

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        setState(() {
          // Prevent duplicate scans.
          hasScanned = true;

          // Show the attendance validation loading overlay.
          isValidating = true;
        });

        // Send the scanned QR token to the backend.
        _markAttendance(value);

        // Process only the first detected QR code.
        break;
      }
    }
  }

  @override
  void dispose() {
    // Release the camera scanner resources.
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111517),
      body: SafeArea(
        child: Column(
          children: [
            // ----- TOP BAR -----
            SizedBox(
              height: 65,
              child: Row(
                children: [
                  // BACK BUTTON
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),

                  // TITLE
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Scan QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // FLASH BUTTON
                  IconButton(
                    onPressed: () {
                      scannerController.toggleTorch();
                    },
                    icon: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                    ),
                  ),

                  // Balances the layout of the top bar.
                  const SizedBox(width: 10),
                ],
              ),
            ),

            // ----- SCANNER AREA -----
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // CAMERA AND SCANNER UI
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // BLUE SCANNING FRAME
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF1976FF),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),

                          // REAL CAMERA QR SCANNER
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: MobileScanner(
                              controller: scannerController,
                              onDetect: _onDetect,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // SCANNING INSTRUCTION
                        const Text(
                          'Align the QR code within the frame\nto scan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // VALIDATING ATTENDANCE OVERLAY
                  if (isValidating)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C2225),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // LOADING INDICATOR
                                CircularProgressIndicator(),

                                SizedBox(height: 20),

                                // LOADING MESSAGE
                                Text(
                                  'Validating attendance...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 8),

                                Text(
                                  'Please wait',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}