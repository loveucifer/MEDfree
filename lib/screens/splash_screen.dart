// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure the Scaffold itself is transparent to allow the body's gradient to show
      backgroundColor: Colors.transparent,
      body: Container(
        // Apply the gradient background here
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Define your desired gradient colors (white to purple)
            // Adjust these colors based on the exact shades you want from your image
            colors: [
              Color(0xFFEDE7F6), // A very light purple/off-white for the top left
              Color(0xFFD1C4E9), // A slightly darker purple
              Color(0xFF9575CD), // A medium purple
              Color(0xFF673AB7), // A deeper purple for the bottom right
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your splash logo (e.g., "thrive being" with MEDfree)
              Image.asset(
                'assets/splash_logo.png', // Ensure this path is correct in pubspec.yaml
                width: 250, // Adjust size as needed
                height: 250, // Adjust size as needed
              ),
              const SizedBox(height: 20),
              // You can add a loading indicator or text if desired,
              // ensuring its color contrasts with the gradient.
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
