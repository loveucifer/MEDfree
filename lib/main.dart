// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Wrap the entire initialization process in a try-catch block.
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // These are the most likely points of failure.
    await dotenv.load(fileName: ".env");
    await NotificationService().init();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // If everything succeeds, run the normal app.
    runApp(const MEDfreeApp());

  } catch (error) {
    // If any error occurs during initialization, run a special ErrorApp
    // that will display the error message. This prevents getting stuck.
    runApp(ErrorApp(error: error.toString()));
  }
}

// A simple widget to display startup errors.
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "Application Failed to Start",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "There was a critical error during initialization. Please check your configuration.\n\nError details:\n$error",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The rest of your app code remains the same.
final supabase = Supabase.instance.client;

class MEDfreeApp extends StatelessWidget {
  const MEDfreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDfree',
      theme: ThemeData(
        // Use a less intense primarySwatch to align with the lighter gradient
        primarySwatch: _createMaterialColor(const Color(0xFF9370DB)), // MediumPurple
        scaffoldBackgroundColor: Colors.transparent, // Allow body to provide gradient
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: _createMaterialColor(const Color(0xFF9370DB)), // MediumPurple
          accentColor: const Color(0xFF87CEEB), // SkyBlue for secondary accent
        ).copyWith(
          // Refined colors based on the desired white-purple gradient and button colors
          primary: const Color(0xFF9370DB), // MediumPurple for primary elements
          onPrimary: Colors.white,
          secondary: const Color(0xFF87CEEB), // SkyBlue for secondary elements
          onSecondary: Colors.white,
          surface: Colors.white, // Card background (slightly opaque in cards directly)
          onSurface: Colors.black87,
          background: Colors.transparent, // Allow body to provide background
          onBackground: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: Colors.black87), // Darker text for dashboards
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.black87), // Darker text
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
          // Default text for gradient screens will be overridden locally
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Consistent rounded corners
          ),
          color: Colors.white.withOpacity(0.9), // Slightly transparent white for cards
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9370DB), // Main button color (MediumPurple)
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded buttons
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF87CEEB), // Text color for outlined button (SkyBlue)
            side: const BorderSide(color: Color(0xFF87CEEB), width: 1.5), // Border color (SkyBlue)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9370DB), // Text color for text buttons (MediumPurple)
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF9370DB), width: 2.0), // Primary focus (MediumPurple)
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }

  // Helper function to create a MaterialColor from a single Color
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      throw Exception('Could not fetch user profile. Please check your network and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { // FIX: Changed 'Connection.waiting' to 'ConnectionState.waiting'
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return const AuthScreen();
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getProfile(session.user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) { // FIX: Changed 'Connection.waiting' to 'ConnectionState.waiting'
                return const SplashScreen();
              }
              if (profileSnapshot.hasError) {
                return Scaffold(
                  body: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFEDE7F6), // Top left
                          Color(0xFFD1C4E9),
                          Color(0xFF9575CD),
                          Color(0xFF673AB7), // Bottom right
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Error Loading Profile",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black87), // Ensure text color is visible
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profileSnapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54), // Ensure text color is visible
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => supabase.auth.signOut(),
                              child: const Text("Sign Out & Try Again"),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              final profile = profileSnapshot.data;
              if (profile == null || profile['full_name'] == null) {
                return const OnboardingScreen();
              }
              return const AppShell();
            },
          );
        }
        return const AuthScreen();
      },
    );
  }
}
