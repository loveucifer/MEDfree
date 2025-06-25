// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Controllers for the form fields
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

  /// Loads the user's profile data from the database.
  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('profiles').select().eq('id', userId).single();

      // Populate controllers with existing data
      _nameController.text = data['full_name'] ?? '';
      _heightController.text = (data['height_cm'] ?? '').toString();
      _currentWeightController.text = (data['current_weight_kg'] ?? '').toString();
      _goalWeightController.text = (data['goal_weight_kg'] ?? '').toString();

    } catch (e) {
      if(mounted) setState(() { _errorMessage = "Could not load profile."; });
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  /// Updates the user's profile and logs weight history.
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final newWeight = double.tryParse(_currentWeightController.text.trim());

      // Use the 'update_profile_and_log_weight' RPC to perform a transaction
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16)))
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                _buildTextFormField(controller: _nameController, label: 'Full Name', validator: _requiredValidator),
                                const SizedBox(height: 16),
                                _buildTextFormField(controller: _heightController, label: 'Height (cm)', keyboardType: TextInputType.number, validator: _requiredValidator),
                                const SizedBox(height: 16),
                                _buildTextFormField(controller: _currentWeightController, label: 'Current Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredValidator),
                                const SizedBox(height: 16),
                                _buildTextFormField(controller: _goalWeightController, label: 'Goal Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _requiredValidator),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

  /// Helper widget to build a consistently styled TextFormField.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    // This TextFormField uses the styles defined in the main.dart InputDecorationTheme.
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100, // Light fill for contrast inside the card
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  /// A simple validator to ensure a field is not empty.
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
