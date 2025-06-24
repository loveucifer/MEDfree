// screens/add_food_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _selectedMealType = 'breakfast';
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _logFood() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "User not authenticated";

      final foodData = {
        'user_id': user.id,
        'food_name': _nameController.text.trim(),
        'calories': double.parse(_caloriesController.text.trim()),
        'protein_g': _proteinController.text.isNotEmpty ? double.parse(_proteinController.text.trim()) : null,
        'carbs_g': _carbsController.text.isNotEmpty ? double.parse(_carbsController.text.trim()) : null,
        'fat_g': _fatController.text.isNotEmpty ? double.parse(_fatController.text.trim()) : null,
        'meal_type': _selectedMealType,
      };

      await supabase.from('food_diary').insert(foodData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal logged successfully!'), backgroundColor: Colors.green),
        );
        // Pop screen and return 'true' to signal a refresh is needed
        Navigator.pop(context, true); 
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging meal: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text('Log a Meal'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Meal Type Selector
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(labelText: 'Meal Type'),
                items: ['breakfast', 'lunch', 'dinner', 'snack']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _selectedMealType = value; });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Form Fields
              _buildTextFormField(controller: _nameController, label: 'Food Name', validator: _requiredValidator),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _caloriesController, label: 'Calories', keyboardType: TextInputType.number, validator: _requiredValidator),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _proteinController, label: 'Protein (g)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _carbsController, label: 'Carbs (g)', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _fatController, label: 'Fat (g)', keyboardType: TextInputType.number),
              
              const SizedBox(height: 40),

              // Submit Button
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _logFood,
                  child: const Text('Log Food'),
                ),
            ],
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
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}