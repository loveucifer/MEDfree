// lib/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      appBar: AppBar(
        title: Text(
          'Scan Barcode',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // White text for app bar
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        foregroundColor: Colors.white, // Default icon/text color for app bar
        elevation: 0, // No shadow
      ),
      body: Container( // Wrap body in a Container for the gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0E0FF), // Very light lavender
              Color(0xFFCCEEFF), // Light sky blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: MobileScanner(
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            torchEnabled: false,
          ),
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
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
