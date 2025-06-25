// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();

      _nameController.text = data['full_name'] ?? '';
      _heightController.text = (data['height_cm'] ?? '').toString();
      _currentWeightController.text = (data['current_weight_kg'] ?? '').toString();
      _goalWeightController.text = (data['goal_weight_kg'] ?? '').toString();

    } catch (e) {
      setState(() { _errorMessage = "Could not load profile."; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final newWeight = double.tryParse(_currentWeightController.text.trim());

      final updates = {
        'id': userId,
        'full_name': _nameController.text.trim(),
        'height_cm': int.tryParse(_heightController.text.trim()),
        'current_weight_kg': newWeight,
        'goal_weight_kg': double.tryParse(_goalWeightController.text.trim()),
      };

      // Use a transaction to update profile and log weight history together
      await supabase.rpc('update_profile_and_log_weight', params: {
          'p_user_id': userId,
          'p_full_name': _nameController.text.trim(),
          'p_height_cm': int.tryParse(_heightController.text.trim()),
          'p_current_weight_kg': newWeight,
          'p_goal_weight_kg': double.tryParse(_goalWeightController.text.trim()),
          'p_weight_log_kg': newWeight
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true); // Pop and signal refresh
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ));
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
          'Edit Profile',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        _buildTextFormField(controller: _nameController, label: 'Full Name', validator: _requiredValidator),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _heightController, label: 'Height (cm)', keyboardType: TextInputType.number, validator: _requiredValidator),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _currentWeightController, label: 'Current Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredValidator),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _goalWeightController, label: 'Goal Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredValidator),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                        )
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
    // These TextFormField styles are mostly inherited from main.dart, but can be overridden here
    // for specific screens if needed.
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        // Ensure label and hint text are visible on the background, if not white already
        labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Dark text for labels
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]), // Lighter hint text
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
