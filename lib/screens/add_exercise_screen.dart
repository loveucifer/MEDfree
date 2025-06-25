// screens/add_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _logExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not authenticated";

      final exerciseData = {
        'user_id': user.id,
        'exercise_name': _nameController.text.trim(),
        'duration_minutes': int.parse(_durationController.text.trim()),
        'calories_burned': double.parse(_caloriesController.text.trim()),
      };

      await supabase.from('exercise_log').insert(exerciseData);

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
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      appBar: AppBar(
        title: Text(
          'Log an Exercise',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // White text for app bar
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // No shadow
        foregroundColor: Colors.white, // Default icon/text color for app bar
      ),
      body: Container( // Wrap body in a Container for the gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0E0FF), // Very light lavender
              Color(0xFFCCEEFF), // Light sky blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextFormField(controller: _nameController, label: 'Exercise Name (e.g., Running)', validator: _requiredValidator),
                const SizedBox(height: 16),
                _buildTextFormField(controller: _durationController, label: 'Duration (minutes)', keyboardType: TextInputType.number, validator: _requiredValidator),
                const SizedBox(height: 16),
                _buildTextFormField(controller: _caloriesController, label: 'Calories Burned', keyboardType: TextInputType.number, validator: _requiredValidator),
                const SizedBox(height: 40),
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
      ),
    );
  }

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
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Dark text for labels
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]), // Lighter hint text
        filled: true, // Make sure it's filled to show background
        fillColor: Colors.white.withOpacity(0.9), // White background for text fields
      ),
      keyboardType: keyboardType,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Dark text for input
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
