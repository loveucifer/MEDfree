// screens/add_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import for theme colors

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();

  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  /// Validates the form and logs the exercise to the database.
  Future<void> _logExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not authenticated";

      await supabase.from('exercise_log').insert({
        'user_id': user.id,
        'exercise_name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'calories_burned': double.parse(_caloriesController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise logged successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to signal a refresh
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging exercise: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Log an Exercise'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MEDfreeApp.primaryColor, MEDfreeApp.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildTextFormField(controller: _nameController, label: 'Exercise Name (e.g., Running)', validator: _requiredValidator),
                      const SizedBox(height: 16),
                      _buildTextFormField(controller: _durationController, label: 'Duration (minutes)', keyboardType: TextInputType.number, validator: _requiredValidator),
                      const SizedBox(height: 16),
                      _buildTextFormField(controller: _caloriesController, label: 'Calories Burned', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredValidator),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _logExercise,
                  child: const Text('Log Exercise'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for creating a styled TextFormField.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  /// Simple validator to ensure a field is not empty.
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
