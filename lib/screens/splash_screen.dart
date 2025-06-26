// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Import to access MEDfreeApp's defined colors

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to get screen dimensions for responsive layout
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        return Scaffold(
          // The scaffold must be transparent to allow the container's gradient to be visible.
          backgroundColor: Colors.transparent,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            // Apply the application's standard gradient background.
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MEDfreeApp.primaryColor,   // Top-left purple
                  MEDfreeApp.secondaryColor, // Bottom-right blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display the main "thrive being" logo from assets.
                  Image.asset(
                    'assets/thrive_being.png',
                    width: screenWidth * 0.75, // Adjusted width for proportion
                  ),
                  SizedBox(height: screenHeight * 0.12), // Increased spacing to move the logo down
                  // Display the "MEDfree" wordmark from assets.
                  Image.asset(
                    'assets/medfree.png',
                    width: screenWidth * 0.40, // Made the logo smaller
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
