// main.dart


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart'; 
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

// AuthGate is updated to check if the user's profile is complete.
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
          // If the user is logged in, check their profile status
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getProfile(session.user.id),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              final profile = profileSnapshot.data;
              // If profile is missing or a key field like 'full_name' is null,
              // redirect to onboarding.
              if (profile == null || profile['full_name'] == null) {
                return const OnboardingScreen();
              }
              // Otherwise, go to home screen.
              return const HomeScreen();
            },
          );
        }

        // If no session, show auth screen
        return const AuthScreen();
      },
    );
  }

  // Helper function to fetch the user profile from Supabase
  Future<Map<String, dynamic>?> _getProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      // Handle cases where the profile might not exist yet or network errors
      return null;
    }
  }
}
```dart
// screens/onboarding_screen.dart
// NEW FILE: Create this file in your `lib/screens` folder.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Form controllers and variables
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _goalWeightController = TextEditingController();
  String? _selectedActivityLevel;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _nextPage() {
    // Basic validation before going to the next page
    bool valid = true;
    int currentPage = _pageController.page!.round();
    if (currentPage == 0 && _nameController.text.isEmpty) valid = false;
    if (currentPage == 1 && _selectedDate == null) valid = false;
    if (currentPage == 2 && _selectedGender == null) valid = false;
    if (currentPage == 3 && _heightController.text.isEmpty) valid = false;
    if (currentPage == 4 && _currentWeightController.text.isEmpty) valid = false;
    if (currentPage == 5 && _goalWeightController.text.isEmpty) valid = false;
    
    if (valid) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the details to continue.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _submitProfile() async {
    if (_selectedActivityLevel == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an activity level.'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    setState(() { _isLoading = true; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "Not authenticated!";

      final profileData = {
        'id': user.id,
        'full_name': _nameController.text.trim(),
        'date_of_birth': _selectedDate!.toIso8601String(),
        'gender': _selectedGender,
        'height_cm': int.parse(_heightController.text.trim()),
        'initial_weight_kg': double.parse(_currentWeightController.text.trim()),
        'current_weight_kg': double.parse(_currentWeightController.text.trim()),
        'goal_weight_kg': double.parse(_goalWeightController.text.trim()),
        'activity_level': _selectedActivityLevel,
        // You could calculate a default calorie goal here or in a Supabase Edge Function
      };

      await supabase.from('profiles').update(profileData).eq('id', user.id);

      if (mounted) {
        // Force AuthGate to re-evaluate by triggering a state change in the auth stream
        // A simple way is to just let AuthGate's FutureBuilder re-run on next build
         Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthGate()), 
          (route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _pageController.hasClients && _pageController.page?.round() != 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: [
          _buildTextPage("What's your full name?", _nameController, "e.g. John Doe"),
          _buildDatePage("What's your date of birth?", _selectDate),
          _buildChoicePage<String>(
              "Select your gender",
              _selectedGender,
              ['male', 'female', 'other'],
              (value) => setState(() => _selectedGender = value)),
          _buildTextPage("What's your height in cm?", _heightController, "e.g. 175", keyboardType: TextInputType.number),
          _buildTextPage("What's your current weight in kg?", _currentWeightController, "e.g. 70.5", keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _buildTextPage("What's your goal weight in kg?", _goalWeightController, "e.g. 65", keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _buildChoicePage<String>(
              "Describe your activity level",
              _selectedActivityLevel,
              ['sedentary', 'light', 'moderate', 'active'],
              (value) => setState(() => _selectedActivityLevel = value)),
        ],
      ),
    );
  }

  Widget _buildPage({required String title, required Widget child, bool isFinalPage = false}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          child,
          const Spacer(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: isFinalPage ? _submitProfile : _nextPage,
              child: Text(isFinalPage ? 'Finish Setup' : 'Continue'),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextPage(String title, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return _buildPage(
      title: title,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: hint,
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
  
  Widget _buildDatePage(String title, Function(BuildContext) pickDate) {
    return _buildPage(
      title: title,
      child: GestureDetector(
        onTap: () => pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _selectedDate == null ? 'Select Date' : '${_selectedDate!.toLocal()}'.split(' ')[0],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildChoicePage<T>(String title, T? groupValue, List<T> items, ValueChanged<T?> onChanged) {
    bool isFinalPage = title.contains("activity");
    return _buildPage(
      title: title,
      isFinalPage: isFinalPage,
      child: Column(
        children: items.map((item) {
          return Card(
             color: groupValue == item ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Colors.white,
            elevation: groupValue == item ? 4 : 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: groupValue == item ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    width: 2)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Text(
                      item.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: groupValue == item ? Theme.of(context).colorScheme.primary : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```dart
// screens/splash_screen.dart
// No changes needed.

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading MEDfree...'),
          ],
        ),
      ),
    );
  }
}
```dart
// screens/auth_screen.dart
// No changes needed.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        _showErrorSnackBar('Check your email for a confirmation link!', isError: false);
        setState(() { _isLogin = true; });
      }
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _showErrorSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome to MEDfree', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(_isLogin ? 'Sign in to continue' : 'Create your account', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _isLogin ? _signIn : _signUp, child: Text(_isLogin ? 'Sign In' : 'Sign Up')),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```dart
// screens/home_screen.dart
// No changes needed.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MEDfree Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? 'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
             const SizedBox(height: 30),
            const Text(
              'Dashboard UI is next!',
              style: TextStyle(color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}
