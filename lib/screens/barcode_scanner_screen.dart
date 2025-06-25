// lib/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../main.dart'; // Import for theme colors

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Scaffold must be transparent to allow the Container's gradient to show.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Extend the body to fill the area behind the AppBar.
      extendBodyBehindAppBar: true,
      body: Container(
        // Apply the standard app gradient to the background.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MEDfreeApp.primaryColor,
              MEDfreeApp.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: MobileScanner(
          // Controller for camera settings.
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            torchEnabled: false,
          ),
          // Callback for when a barcode is detected.
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              // If a valid code is found, pop the screen and return the code.
              if (code != null && code.isNotEmpty) {
                Navigator.of(context).pop(code);
              }
            }
          },
        ),
      ),
    );
  }
}
