import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/api_service.dart';
import 'attendance_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final int studentId;
  final String accessToken;

  const ScannerScreen({
    super.key,
    required this.studentId,
    required this.accessToken,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  final ApiService apiService = ApiService();

  bool hasScanned = false;
  bool isValidating = false;
  bool deviceVerified = false;
  bool faceVerified = false;
  bool bleVerified = false;

  String? faceProof;

  String validationMessage = 'Validating attendance...';

  static const String baseUrl = 'http://127.0.0.1:8000';

  // ============================================================
  // TEACHER BLE BEACON
  // ============================================================

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

  // ============================================================
  // VERIFY TEACHER BLE
  // ============================================================

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

  // ============================================================
  // CAPTURE FACE
  // ============================================================

  Future<XFile?> _captureFace() async {
    try {
      final cameraPermission = await Permission.camera.request();

      if (!cameraPermission.isGranted) {
        return null;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        return null;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return null;
      }

      final XFile? image = await showDialog<XFile>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(15),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return SizedBox(
                  width: double.infinity,
                  height: 520,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          'Face Verification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CameraPreview(controller),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Position your face clearly inside the camera view.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, null);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final photo = await controller
                                        .takePicture();

                                    if (!dialogContext.mounted) {
                                      return;
                                    }

                                    Navigator.pop(dialogContext, photo);
                                  } catch (e) {
                                    if (!dialogContext.mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not capture face: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Capture'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      await controller.dispose();

      return image;
    } catch (e) {
      print('FACE CAMERA ERROR: $e');
      return null;
    }
  }

  // ============================================================
  // VERIFY FACE WITH BACKEND
  // ============================================================

  Future<bool> _verifyFace(String qrToken) async {
    final XFile? image = await _captureFace();

    if (image == null) {
      return false;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/attendance/face/verify/'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.accessToken}';

      // Send the QR token together with the face image.
      request.fields['qr_token'] = qrToken;

      // Explicitly send the captured image as JPEG.
      request.files.add(
        await http.MultipartFile.fromPath(
          'live_image',
          image.path,
          filename: 'live_face.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      print('========================================');
      print('FACE VERIFICATION REQUEST');
      print('FACE VERIFICATION STATUS: ${response.statusCode}');
      print('FACE VERIFICATION BODY: ${response.body}');
      print('========================================');

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (e) {
        print('FACE JSON PARSE ERROR: $e');
      }

      if (response.statusCode == 200 && data['verified'] == true) {
        final proof = data['face_proof']?.toString();

        if (proof == null || proof.isEmpty) {
          print(
            'FACE VERIFICATION ERROR: '
            'No face proof received',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Face verification proof was not received.'),
                backgroundColor: Colors.red,
              ),
            );
          }

          return false;
        }

        faceProof = proof;

        print('FACE PROOF RECEIVED: true');

        return true;
      }

      final errorMessage =
          data['error']?.toString() ?? 'Face verification failed.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }

      return false;
    } catch (e) {
      print('FACE VERIFICATION CONNECTION ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not verify face: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  // ============================================================
  // MARK ATTENDANCE
  // ============================================================

  Future<void> _markAttendance(String qrToken) async {
    try {
      if (faceProof == null || faceProof!.isEmpty) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face verification proof is missing.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/attendance/mark/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': widget.studentId,
          'qr_token': qrToken,
          'face_proof': faceProof,
          'ble_verified': bleVerified,
        }),
      );

      print('========================================');
      print('ATTENDANCE REQUEST');
      print('Student ID: ${widget.studentId}');
      print('QR Token: $qrToken');
      print('Face Proof Present: ${faceProof != null}');
      print('BLE Verified: $bleVerified');
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

      // ========================================================
      // ATTENDANCE SUCCESS
      // ========================================================

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

      // ========================================================
      // ATTENDANCE FAILED
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        hasScanned = false;
        isValidating = false;
        deviceVerified = false;
        faceVerified = false;
        bleVerified = false;
        faceProof = null;
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
        deviceVerified = false;
        faceVerified = false;
        bleVerified = false;
        faceProof = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not connect to server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // QR DETECTION
  // ============================================================

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
          deviceVerified = false;
          faceVerified = false;
          bleVerified = false;
          faceProof = null;
          validationMessage = 'Checking registered device...';
        });

        print('QR CODE DETECTED: $value');

        // ======================================================
        // STEP 1 — REGISTERED DEVICE
        // ======================================================

        try {
          final registered = await apiService.isDeviceRegistered(
            accessToken: widget.accessToken,
          );

          if (!registered) {
            if (!mounted) {
              return;
            }

            setState(() {
              hasScanned = false;
              isValidating = false;
              faceProof = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This device is not registered. Please register this device first.',
                ),
                backgroundColor: Colors.red,
              ),
            );

            return;
          }

          if (!mounted) {
            return;
          }

          setState(() {
            deviceVerified = true;
            validationMessage = 'Registered device verified';
          });
        } catch (e) {
          if (!mounted) {
            return;
          }

          setState(() {
            hasScanned = false;
            isValidating = false;
            faceProof = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not verify device: $e'),
              backgroundColor: Colors.red,
            ),
          );

          return;
        }

        // ======================================================
        // STEP 2 — FACE VERIFICATION
        // ======================================================

        if (!mounted) {
          return;
        }

        setState(() {
          validationMessage = 'Face verification required';
        });

        final bool verifiedFace = await _verifyFace(value);

        if (!verifiedFace) {
          if (!mounted) {
            return;
          }

          setState(() {
            hasScanned = false;
            isValidating = false;
            deviceVerified = false;
            faceVerified = false;
            bleVerified = false;
            faceProof = null;
          });

          return;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          faceVerified = true;
          validationMessage = 'Face verified successfully';
        });

        // ======================================================
        // STEP 3 — BLE VERIFICATION
        // ======================================================

        if (!mounted) {
          return;
        }

        setState(() {
          validationMessage = 'Checking teacher BLE beacon...';
        });

        final bool verifiedBle = await _verifyTeacherBeacon();

        if (!verifiedBle) {
          if (!mounted) {
            return;
          }

          setState(() {
            hasScanned = false;
            isValidating = false;
            deviceVerified = false;
            faceVerified = false;
            bleVerified = false;
            faceProof = null;
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

        if (!mounted) {
          return;
        }

        setState(() {
          bleVerified = true;
          validationMessage = 'Teacher BLE verified';
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) {
          return;
        }

        // ======================================================
        // STEP 4 — FINAL SERVER-SIDE CHECK
        // ======================================================

        setState(() {
          validationMessage = 'Recording attendance...';
        });

        await _markAttendance(value);

        break;
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111517),
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // TOP BAR
            // ==================================================

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

            // ==================================================
            // SCANNER
            // ==================================================
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: scannerController,
                    onDetect: _onDetect,
                  ),

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

                  // ==================================================
                  // VALIDATION OVERLAY
                  // ==================================================
                  if (isValidating)
                    Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (deviceVerified &&
                                faceVerified &&
                                bleVerified) ...[
                              const Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                                size: 55,
                              ),

                              const SizedBox(height: 18),

                              const Text(
                                'All verifications passed',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                validationMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ] else ...[
                              const CircularProgressIndicator(
                                color: Color(0xFF1976FF),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                validationMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
