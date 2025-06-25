// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Import to access MEDfreeApp's defined colors

class SplashScreen extends StatefulWidget { // Changed to StatefulWidget
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // The timer here is for internal operations of SplashScreen,
    // the actual display duration is controlled by AuthGate.
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    // This delay ensures any internal splash screen animations/operations
    // have time to complete. The overall screen display time is handled
    // by AuthGate to guarantee a minimum duration.
    await Future.delayed(const Duration(seconds: 10)); // Increased to 5 seconds
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Ensure Scaffold is transparent
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Use the new colors for the splash screen gradient
            colors: [
              MEDfreeApp.primaryColor, // Top-left lighter purple: #B085EF
              MEDfreeApp.secondaryColor, // Bottom-right bright blue: #00B0F0
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Larger "thrive being" image (corrected asset name)
              Image.asset(
                'assets/thrive_being.png', // Corrected asset name
                width: 250, // Adjust size as needed
                height: 250,
              ),
              const SizedBox(height: 20), // Spacing between the two images/text
              // Smaller "MEDfree" image/text (corrected asset name)
              Image.asset(
                'assets/medfree.png', // Corrected asset name
                width: 150, // Adjust size as needed, smaller than the first
                height: 50,
              ),
              const SizedBox(height: 40), // Spacing before the loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary), // White
              ),
              const SizedBox(height: 20),
              Text(
                'Loading MEDfree...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // Ensure text is visible
              ),
            ],
          ),
        ),
      ),
    );
  }
}
