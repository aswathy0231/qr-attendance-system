import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../services/api_service.dart';
import '../services/device_registration_service.dart';
import 'change_password_screen.dart';

class DeviceRegistrationScreen extends StatefulWidget {
  final StudentModel student;
  final String accessToken;

  const DeviceRegistrationScreen({
    super.key,
    required this.student,
    required this.accessToken,
  });

  @override
  State<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState extends State<DeviceRegistrationScreen> {
  final DeviceRegistrationService _deviceService = DeviceRegistrationService();

  final ApiService _apiService = ApiService();

  String _deviceUuid = '';
  String _deviceName = '';

  bool _isLoading = true;
  bool _isRegistering = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceInformation();
  }

  // ============================================================
  // LOAD DEVICE INFORMATION
  // ============================================================

  Future<void> _loadDeviceInformation() async {
    try {
      final uuid = await _deviceService.getDeviceUuid();

      final name = await _deviceService.getDeviceName();

      if (!mounted) return;

      setState(() {
        _deviceUuid = uuid;
        _deviceName = name;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to get device information.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // REGISTER DEVICE
  // ============================================================

  Future<void> _registerDevice() async {
    if (_deviceUuid.isEmpty) {
      _showMessage('Device information is not available.', isError: true);
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final result = await _apiService.registerDevice(
        deviceUuid: _deviceUuid,
        deviceName: _deviceName,
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showSuccessDialog(
        result['message'] ?? 'Device registered successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text(
                'Success',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () {
                // Close success dialog
                Navigator.pop(dialogContext);

                // Go to change password
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(
                      student: widget.student,
                      accessToken: widget.accessToken,
                    ),
                  ),
                );
              },
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Color(0xFF175CD3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF175CD3),
        foregroundColor: Colors.white,
        title: const Text(
          'Device Registration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF175CD3)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // ==================================================
                  // DEVICE ICON
                  // ==================================================

                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFDDE8FF),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 60,
                      color: Color(0xFF175CD3),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    'Register Your Device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF151A2D),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'This device will be linked to your student account '
                    'for secure attendance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // STUDENT INFORMATION
                  // ==================================================
                  _sectionTitle('Student Information'),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Student', widget.student.name),
                        _infoRow('Student ID', widget.student.registerNumber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // DEVICE INFORMATION
                  // ==================================================
                  _sectionTitle('Device Information'),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Device', _deviceName),
                        _infoRow('Device ID', _deviceUuid),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // INFORMATION MESSAGE
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE8FF)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF175CD3),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only one device can be registered '
                            'for a student account.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF344054),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // REGISTER BUTTON
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isRegistering ? null : _registerDevice,
                      icon: _isRegistering
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.phonelink_lock),
                      label: Text(
                        _isRegistering
                            ? 'Registering...'
                            : 'Register This Device',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF175CD3),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF98A2B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 15),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF151A2D),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _infoRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
