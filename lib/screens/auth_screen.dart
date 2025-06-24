// lib/screens/auth_screen.dart
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