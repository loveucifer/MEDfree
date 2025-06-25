// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Import to access MEDfreeApp's defined colors

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 20),
              // Display the "MEDfree" wordmark from assets.
              Image.asset(
                'assets/medfree.png',
                // Increased size for better visibility
                width: 200,
              ),
              const SizedBox(height: 40),
              // Show a loading indicator to signify that the app is loading data.
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              // Loading text to inform the user of the app's status.
              Text(
                'Loading your wellness journey...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
