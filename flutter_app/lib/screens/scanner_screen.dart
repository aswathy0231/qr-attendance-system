import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controller for the QR scanner
  final MobileScannerController scannerController = MobileScannerController();

  // Prevents the same QR from being processed multiple times
  bool hasScanned = false;

  // Temporary student ID for testing.
  // Later this will come from the logged-in student.
  final int studentId = 1;

  // Django backend URL.
  //
  // For Flutter Web running on the same computer:
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<void> _markAttendance(String qrToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'student_id': studentId,
          'qr_token': qrToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Stop the scanner after successful attendance marking.
        await scannerController.stop();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          hasScanned = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Failed to mark attendance',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        hasScanned = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to the server.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned) return;

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        setState(() {
          hasScanned = true;
        });

        // Send QR token to Django backend.
        _markAttendance(value);

        break;
      }
    }
  }

  @override
  void dispose() {
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
            // TOP BAR
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

                  const SizedBox(width: 10),
                ],
              ),
            ),

            // SCANNER AREA
            Expanded(
              child: Center(
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

                      // REAL CAMERA SCANNER
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: MobileScanner(
                          controller: scannerController,
                          onDetect: _onDetect,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // INSTRUCTION
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
            ),
          ],
        ),
      ),
    );
  }
}
