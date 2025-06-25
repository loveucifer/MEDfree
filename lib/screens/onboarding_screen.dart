// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // <-- ADDED THIS IMPORT
import '../main.dart'; // We need this to access AuthGate and theme colors

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
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

  /// Shows the date picker dialog, styled to match the app's theme.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Theming the date picker to match the app's color scheme.
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: MEDfreeApp.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: MEDfreeApp.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Navigates to the next page in the onboarding sequence.
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Submits the completed profile to the database.
  Future<void> _submitProfile() async {
    // Validate all required fields before submission.
    if (_nameController.text.trim().isEmpty ||
        _selectedDate == null ||
        _selectedGender == null ||
        _heightController.text.trim().isEmpty ||
        _currentWeightController.text.trim().isEmpty ||
        _goalWeightController.text.trim().isEmpty ||
        _selectedActivityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.'), backgroundColor: Colors.redAccent),
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
        // TODO: Calculate this based on user data instead of a default.
        'daily_calorie_goal': 2000,
      };

      await supabase.from('profiles').update(profileData).eq('id', user.id);

      if (mounted) {
        // Navigate to the main app, replacing the onboarding stack.
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      // AppBar is transparent with a white back arrow.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _pageController.hasClients && _pageController.page?.round() != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              )
            : null,
      ),
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
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildTextPage("What's your full name?", _nameController, "e.g. Thrive Being"),
            _buildDatePage("What's your date of birth?", _selectDate),
            _buildChoicePage<String>("Select your gender", _selectedGender, ['male', 'female', 'other'], (value) => setState(() => _selectedGender = value)),
            _buildTextPage("What's your height in cm?", _heightController, "e.g. 175", keyboardType: TextInputType.number),
            _buildTextPage("What's your current weight in kg?", _currentWeightController, "e.g. 70.5", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            _buildTextPage("What's your goal weight in kg?", _goalWeightController, "e.g. 65", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            _buildChoicePage<String>("Describe your activity level", _selectedActivityLevel, ['sedentary', 'light', 'moderate', 'active'], (value) => setState(() => _selectedActivityLevel = value), isFinalPage: true),
          ],
        ),
      ),
    );
  }

  /// A generic builder for a page in the PageView.
  Widget _buildPage({required String title, required Widget child, bool isFinalPage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          child,
          const Spacer(),
          _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : ElevatedButton(
                onPressed: isFinalPage ? _submitProfile : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: MEDfreeApp.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isFinalPage ? 'Finish Setup' : 'Continue'),
              ),
          const SizedBox(height: 60), // Bottom padding
        ],
      ),
    );
  }

  /// Builds a page with a single text input field.
  Widget _buildTextPage(String title, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return _buildPage(
        title: title,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white, width: 2)),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ));
  }

  /// Builds the date selection page.
  Widget _buildDatePage(String title, Function(BuildContext) pickDate) {
    return _buildPage(
        title: title,
        child: GestureDetector(
          onTap: () => pickDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white70)),
            ),
            child: Text(
              _selectedDate == null ? 'Select Date' : DateFormat('MMMM d, yyyy').format(_selectedDate!),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
        ));
  }

  /// Builds a page with a list of choices.
  Widget _buildChoicePage<T>(String title, T? groupValue, List<T> items, ValueChanged<T?> onChanged, {bool isFinalPage = false}) {
    return _buildPage(
      title: title,
      isFinalPage: isFinalPage,
      child: Column(
        children: items.map((item) {
          final isSelected = groupValue == item;
          return Card(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Text(
                    item.toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? MEDfreeApp.primaryColor : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
