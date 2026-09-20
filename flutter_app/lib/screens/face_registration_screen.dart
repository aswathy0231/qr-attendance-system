import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../services/api_service.dart';
import 'device_registration_screen.dart';

class FaceRegistrationScreen extends StatefulWidget {
  final StudentModel student;
  final String accessToken;

  const FaceRegistrationScreen({
    super.key,
    required this.student,
    required this.accessToken,
  });

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ============================================================
  // INITIALIZE FRONT CAMERA
  // ============================================================

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      CameraDescription frontCamera;

      try {
        frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        frontCamera = cameras.first;
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not open the camera.';
      });

      debugPrint('CAMERA ERROR: $e');
    }
  }

  // ============================================================
  // CAPTURE FACE
  // ============================================================

  Future<void> _captureFace() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      print('CAPTURED IMAGE PATH: ${image.path}');

      print(
        'IMAGE EXISTS: '
        '${File(image.path).existsSync()}',
      );

      print(
        'IMAGE SIZE: '
        '${File(image.path).lengthSync()} bytes',
      );

      final apiService = ApiService();

      await apiService.registerFace(
        imageFile: File(image.path),
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face registered successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // ========================================================
      // FACE REGISTRATION SUCCESS
      // GO TO DEVICE REGISTRATION
      // ========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceRegistrationScreen(
            student: widget.student,
            accessToken: widget.accessToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // DISPOSE CAMERA
  // ============================================================

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Face Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && !_isCameraReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 60,
              ),

              const SizedBox(height: 20),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });

                  _initializeCamera();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      children: [
        // ========================================================
        // CAMERA PREVIEW
        // ========================================================

        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(child: CameraPreview(_cameraController!)),

              // Face guide
              Container(
                width: 230,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),

              // Instructions
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Position your face inside the frame\n'
                    'and make sure your face is clearly visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),

              if (_isCapturing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),

        // ========================================================
        // BOTTOM SECTION
        // ========================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          color: Colors.black,
          child: Column(
            children: [
              const Text(
                'Register Your Face',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your face will be securely registered '
                'for attendance verification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),

                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // Capture button
              SizedBox(
                width: 70,
                height: 70,
                child: FloatingActionButton(
                  onPressed: _isCapturing ? null : _captureFace,
                  backgroundColor: Colors.white,
                  child: _isCapturing
                      ? const CircularProgressIndicator()
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 32,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
