import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'attendance_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final int studentId;

  const ScannerScreen({super.key, required this.studentId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  bool hasScanned = false;
  bool isValidating = false;
  bool bleVerified = false;

  static const String baseUrl = 'http://127.0.0.1:8000';

  bool _isTeacherBeacon(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;

    final data = manufacturerData[0xFFFE];

    return data != null &&
        data.length >= 4 &&
        data[0] == 0x51 &&
        data[1] == 0x52 &&
        data[2] == 0x41 &&
        data[3] == 0x54;
  }

  Future<bool> _verifyTeacherBeacon() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      return false;
    }

    final locationStatus = await Permission.locationWhenInUse.request();

    if (!locationStatus.isGranted) {
      return false;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;

    if (adapterState != BluetoothAdapterState.on) {
      return false;
    }

    bool beaconFound = false;

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (_isTeacherBeacon(result)) {
          beaconFound = true;
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      await Future.delayed(const Duration(seconds: 10));
    } finally {
      await FlutterBluePlus.stopScan();
      await subscription.cancel();
    }

    return beaconFound;
  }

  Future<void> _markAttendance(String qrToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': widget.studentId,
          'qr_token': qrToken,
          'ble_verified': true,
        }),
      );

      print('========================================');
      print('ATTENDANCE REQUEST');
      print('Student ID: ${widget.studentId}');
      print('QR Token: $qrToken');
      print('ATTENDANCE STATUS: ${response.statusCode}');
      print('ATTENDANCE BODY: ${response.body}');
      print('========================================');

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (jsonError) {
        print('JSON PARSE ERROR: $jsonError');
      }

      // Attendance successfully marked
      if (response.statusCode == 201) {
        await scannerController.stop();

        if (!mounted) {
          return;
        }

        setState(() {
          isValidating = false;
        });

        final String subject = data['subject']?.toString() ?? 'Not available';

        final String date = data['date']?.toString() ?? 'Not available';

        final String time = data['time']?.toString() ?? 'Not available';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceResultScreen(
              subject: subject,
              date: date,
              time: time,
            ),
          ),
        );

        return;
      }

      // Attendance failed
      if (!mounted) {
        return;
      }

      setState(() {
        hasScanned = false;
        isValidating = false;
        bleVerified = false;
      });

      final String errorMessage =
          data['error']?.toString() ??
          data['message']?.toString() ??
          'Failed to mark attendance';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('ATTENDANCE CONNECTION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        hasScanned = false;
        isValidating = false;
        bleVerified = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (hasScanned) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;

      if (value != null && value.isNotEmpty) {
        setState(() {
          hasScanned = true;
          isValidating = true;
          bleVerified = false;
        });

        print('QR CODE DETECTED: $value');

        final bool verified = await _verifyTeacherBeacon();

        if (!verified) {
          if (!mounted) {
            return;
          }

          setState(() {
            hasScanned = false;
            isValidating = false;
            bleVerified = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Teacher BLE beacon not detected. Please move closer to the teacher.',
              ),
              backgroundColor: Colors.red,
            ),
          );

          return;
        }

        // BLE verification successful
        if (!mounted) {
          return;
        }

        setState(() {
          bleVerified = true;
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) {
          return;
        }

        await _markAttendance(value);

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
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      scannerController.toggleTorch();
                    },
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Scanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: scannerController,
                    onDetect: _onDetect,
                  ),

                  // Scanner frame
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF1976FF),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  // Instruction text
                  Positioned(
                    bottom: 80,
                    left: 30,
                    right: 30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Align the QR code within the frame to scan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),

                  // Validation overlay
                  if (isValidating)
                    Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bleVerified) ...[
                              const Icon(
                                Icons.bluetooth_connected,
                                color: Colors.greenAccent,
                                size: 55,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Teacher BLE verified',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Recording attendance...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ] else ...[
                              const CircularProgressIndicator(
                                color: Color(0xFF1976FF),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Validating attendance...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Please wait',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
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
