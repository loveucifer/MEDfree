// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../main.dart'; // Import to use the app's theme colors

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

  /// Handles the sign-in process.
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

  /// Handles the sign-up process.
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

  /// Displays a SnackBar with an error or success message.
  void _showErrorSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold is transparent to let the gradient from the Container show through.
      backgroundColor: Colors.transparent,
      body: Container(
        // Apply the standard app gradient.
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
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome to MEDfree',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Sign in to continue' : 'Create your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    // Email text field styled for the gradient background.
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildInputDecoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || !value.contains('@')) ? 'Please enter a valid email' : null,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // Password text field styled for the gradient background.
                    TextFormField(
                      controller: _passwordController,
                      decoration: _buildInputDecoration('Password'),
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    // Loading indicator or the main action button.
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : ElevatedButton(
                            onPressed: _isLogin ? _signIn : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: MEDfreeApp.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                          ),
                    const SizedBox(height: 16),
                    // Button to toggle between Sign In and Sign Up modes.
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to create a consistent InputDecoration for text fields.
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      // Border style when the field is not focused.
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white70, width: 1.0),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
      // Border style when the field is focused.
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2.0),
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
      ),
    );
  }
}
