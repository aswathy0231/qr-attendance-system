import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

/// Screen that opens the device camera, scans a QR code, and submits it
/// to the backend to mark the student's attendance.
class ScannerScreen extends StatefulWidget {
  final int studentId;

  const ScannerScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controller for the QR scanner.
  final MobileScannerController scannerController = MobileScannerController();

  // Prevents the same QR from being processed multiple times.
  bool hasScanned = false;

  // Indicates whether attendance is currently being validated.
  bool isValidating = false;

  // Django backend URL.
  //
  // Keep this as 127.0.0.1 because we are using:
  // adb reverse tcp:8000 tcp:8000
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Sends the scanned QR token and the logged-in student's ID
  /// to the Django backend.
  Future<void> _markAttendance(String qrToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'student_id': widget.studentId,
          'qr_token': qrToken,
        }),
      );

      // DEBUG INFORMATION
      print('========================================');
      print('ATTENDANCE REQUEST');
      print('Student ID: ${widget.studentId}');
      print('QR Token: $qrToken');
      print('ATTENDANCE STATUS: ${response.statusCode}');
      print('ATTENDANCE BODY: ${response.body}');
      print('========================================');

      if (!mounted) return;

      // Try to decode the response as JSON.
      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (jsonError) {
        print('JSON DECODE ERROR: $jsonError');
      }

      if (response.statusCode == 201) {
        // Stop scanner after successful attendance marking.
        await scannerController.stop();

        if (!mounted) return;

        setState(() {
          isValidating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Allow scanning again after an unsuccessful request.
        setState(() {
          hasScanned = false;
          isValidating = false;
        });

        final errorMessage = data['error']?.toString() ??
            data['message']?.toString() ??
            'Failed to mark attendance '
                '(HTTP ${response.statusCode})';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('========================================');
      print('ATTENDANCE CONNECTION ERROR');
      print(e);
      print('========================================');

      if (!mounted) return;

      setState(() {
        hasScanned = false;
        isValidating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect to the server.\n$e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

        print('QR CODE DETECTED: $value');

        // Send QR token to Django backend.
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
