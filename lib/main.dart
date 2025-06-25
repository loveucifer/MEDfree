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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await dotenv.load(fileName: ".env");
    await NotificationService().init();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    
    runApp(const MEDfreeApp());

  } catch (error) {
    runApp(ErrorApp(error: error.toString()));
  }
}

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

final supabase = Supabase.instance.client;

class MEDfreeApp extends StatelessWidget {
  const MEDfreeApp({super.key});

  static const Color primaryColor = Color(0xFFB085EF);
  static const Color secondaryColor = Color(0xFF00B0F0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDfree',
      theme: ThemeData(
        primarySwatch: _createMaterialColor(primaryColor),
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: _createMaterialColor(primaryColor),
          accentColor: secondaryColor,
        ).copyWith(
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: secondaryColor,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.transparent,
          onBackground: Colors.black87,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0, color: Colors.black87),
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          color: Colors.white.withOpacity(0.9),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            borderSide: const BorderSide(color: primaryColor, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }

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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // This future ensures the splash screen is shown for at least 4 seconds.
    _initFuture = Future.delayed(const Duration(seconds: 4));
  }

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
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // While the 4-second delay is active, show the splash screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // After the delay, check the auth state.
        return StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, authSnapshot) {
            // While waiting for the first auth state, continue showing splash.
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final session = authSnapshot.data?.session;

            if (session != null) {
              return FutureBuilder<Map<String, dynamic>?>(
                future: _getProfile(session.user.id),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  }

                  if (profileSnapshot.hasError) {
                    return Scaffold(
                      body: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [MEDfreeApp.primaryColor, MEDfreeApp.secondaryColor],
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
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  profileSnapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => supabase.auth.signOut(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: MEDfreeApp.primaryColor,
                                  ),
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
      },
    );
  }
}
