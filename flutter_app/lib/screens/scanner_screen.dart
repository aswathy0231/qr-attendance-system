import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Controller for the QR scanner
  final MobileScannerController scannerController =
      MobileScannerController();

  // To prevent scanning the same QR multiple times
  bool hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (hasScanned) return;

    for (final barcode in capture.barcodes) {
      final String? value = barcode.rawValue;

      if (value != null) {
        hasScanned = true;

        // Show the detected QR data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR detected: $value'),
          ),
        );

        print('QR Data: $value');

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

                        borderRadius:
                            BorderRadius.circular(18),
                      ),

                      // REAL CAMERA SCANNER
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(15),

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