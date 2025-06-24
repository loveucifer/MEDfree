// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart'; // Import the service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().init();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MEDfreeApp());
}

final supabase = Supabase.instance.client;

class MEDfreeApp extends StatelessWidget {
  const MEDfreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDfree',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE53935),
          secondary: Color(0xFFFFC107),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          background: Color(0xFFFAFAFA),
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: Colors.black87),
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// AuthGate remains the same
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getProfile(session.user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
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

  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    try {
      final response = await supabase.from('profiles').select().eq('id', userId).single();
      return response;
    } catch (e) {
      return null;
    }
  }
}