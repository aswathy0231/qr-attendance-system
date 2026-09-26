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
  bool _isRegistering = false;

  String? _errorMessage;

  // ============================================================
  // FACE IMAGES
  // ============================================================

  File? _frontImage;
  File? _leftImage;
  File? _rightImage;

  // ============================================================
  // CURRENT STEP
  // 0 = FRONT
  // 1 = LEFT
  // 2 = RIGHT
  // ============================================================

  int _currentStep = 0;

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
  // CAPTURE CURRENT FACE
  // ============================================================

  Future<void> _captureFace() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        _isRegistering) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final XFile image = await _cameraController!.takePicture();

      final File imageFile = File(image.path);

      print('CAPTURED IMAGE PATH: ${image.path}');

      print(
        'IMAGE EXISTS: '
        '${imageFile.existsSync()}',
      );

      print(
        'IMAGE SIZE: '
        '${imageFile.lengthSync()} bytes',
      );

      if (!mounted) return;

      setState(() {
        if (_currentStep == 0) {
          _frontImage = imageFile;
        } else if (_currentStep == 1) {
          _leftImage = imageFile;
        } else if (_currentStep == 2) {
          _rightImage = imageFile;
        }

        _isCapturing = false;
      });

      // --------------------------------------------------------
      // Move to next step
      // --------------------------------------------------------

      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      } else {
        // All three images captured
        await _registerAllFaces();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _errorMessage = 'Could not capture the image.';
      });

      debugPrint('CAPTURE ERROR: $e');
    }
  }

  // ============================================================
  // REGISTER ALL THREE FACES
  // ============================================================

  Future<void> _registerAllFaces() async {
    if (_frontImage == null ||
        _leftImage == null ||
        _rightImage == null ||
        _isRegistering) {
      return;
    }

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      print('REGISTERING THREE FACE VIEWS...');

      final apiService = ApiService();

      await apiService.registerFace(
        frontImage: _frontImage!,
        leftImage: _leftImage!,
        rightImage: _rightImage!,
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All three face views registered successfully.'),
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
        _isRegistering = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // STEP TITLE
  // ============================================================

  String get _stepTitle {
    if (_currentStep == 0) {
      return 'Look Straight';
    }

    if (_currentStep == 1) {
      return 'Turn Your Head Left';
    }

    return 'Turn Your Head Right';
  }

  // ============================================================
  // STEP INSTRUCTION
  // ============================================================

  String get _stepInstruction {
    if (_currentStep == 0) {
      return 'Look directly at the camera and keep your face straight.';
    }

    if (_currentStep == 1) {
      return 'Slowly turn your head to the left and keep your face clearly visible.';
    }

    return 'Slowly turn your head to the right and keep your face clearly visible.';
  }

  // ============================================================
  // BUTTON TEXT
  // ============================================================

  String get _buttonText {
    if (_currentStep == 0) {
      return 'Capture Front Face';
    }

    if (_currentStep == 1) {
      return 'Capture Left Face';
    }

    return 'Capture Right Face';
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

  // ============================================================
  // BODY
  // ============================================================

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
        // ======================================================
        // STEP INDICATOR
        // ======================================================

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          color: Colors.black,
          child: Row(
            children: [
              _buildStepIndicator(0, 'Front'),

              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= 1 ? Colors.green : Colors.white24,
                ),
              ),

              _buildStepIndicator(1, 'Left'),

              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= 2 ? Colors.green : Colors.white24,
                ),
              ),

              _buildStepIndicator(2, 'Right'),
            ],
          ),
        ),

        // ======================================================
        // CAMERA PREVIEW
        // ======================================================
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
                  child: Column(
                    children: [
                      Text(
                        _stepTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _stepInstruction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Processing overlay
              if (_isCapturing || _isRegistering)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 15),
                        Text(
                          _isRegistering
                              ? 'Registering your face...'
                              : 'Capturing...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ======================================================
        // BOTTOM SECTION
        // ======================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          color: Colors.black,
          child: Column(
            children: [
              Text(
                _buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${_currentStep + 1} of 3',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                  onPressed: (_isCapturing || _isRegistering)
                      ? null
                      : _captureFace,
                  backgroundColor: Colors.white,
                  child: (_isCapturing || _isRegistering)
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

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _buildStepIndicator(int step, String label) {
    final bool completed = step < _currentStep;

    final bool current = step == _currentStep;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? Colors.green
                : current
                ? Colors.white
                : Colors.white24,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: current ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: current || completed ? Colors.white : Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
