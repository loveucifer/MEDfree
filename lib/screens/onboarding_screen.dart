// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // We need this to access AuthGate

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) { // Custom builder for the date picker to inherit theme
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary, // Your app's primary color
              onPrimary: Theme.of(context).colorScheme.onPrimary, // White
              surface: Colors.white, // Background of the date picker dialog
              onSurface: Colors.black87, // Text/icon color on the date picker background
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, // Buttons in dialog
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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        'daily_calorie_goal': 2000, // Default value
      };

      await supabase.from('profiles').update(profileData).eq('id', user.id);

      if (mounted) {
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
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _pageController.hasClients && _pageController.page?.round() != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white), // White icon
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              )
            : null,
      ),
      body: Container( // Wrap body in a Container for the gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE7F6), // Top left (white-ish)
              Color(0xFFD1C4E9), // Light purple
              Color(0xFF9575CD), // Medium purple
              Color(0xFF673AB7), // Bottom right (deep purple)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildTextPage("What's your full name?", _nameController, "e.g. John Doe"),
            _buildDatePage("What's your date of birth?", _selectDate),
            _buildChoicePage<String>("Select your gender", _selectedGender, ['male', 'female', 'other'], (value) => setState(() => _selectedGender = value)),
            _buildTextPage("What's your height in cm?", _heightController, "e.g. 175", keyboardType: TextInputType.number),
            _buildTextPage("What's your current weight in kg?", _currentWeightController, "e.g. 70.5", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            _buildTextPage("What's your goal weight in kg?", _goalWeightController, "e.g. 65", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            _buildChoicePage<String>("Describe your activity level", _selectedActivityLevel, ['sedentary', 'light', 'moderate', 'active'], (value) => setState(() => _selectedActivityLevel = value)),
          ],
        ),
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
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white), textAlign: TextAlign.center), // White text for title
          const SizedBox(height: 40),
          child,
          const Spacer(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) // White indicator
          else
            ElevatedButton(
              onPressed: isFinalPage ? _submitProfile : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // White button for contrast
                foregroundColor: Theme.of(context).colorScheme.primary, // Text color matches primary
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text(isFinalPage ? 'Finish Setup' : 'Continue'),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextPage(String title, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return _buildPage(title: title, child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.white70), // White text for labels
          hintStyle: const TextStyle(color: Colors.white54), // Lighter white hint text
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70, width: 1.0),
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, color: Colors.white), // White input text
      ),
    );
  }

  Widget _buildDatePage(String title, Function(BuildContext) pickDate) {
    return _buildPage(title: title, child: GestureDetector(
        onTap: () => pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70), // White border
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.2), // Slightly transparent white fill
          ),
          child: Text(
            _selectedDate == null ? 'Select Date' : '${_selectedDate!.toLocal()}'.split(' ')[0],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: Colors.white), // White text
          ),
        ),
      ),
    );
  }

  Widget _buildChoicePage<T>(String title, T? groupValue, List<T> items, ValueChanged<T?> onChanged) {
    bool isFinalPage = title.contains("activity");
    return _buildPage(
      title: title, isFinalPage: isFinalPage,
      child: Column(
        children: items.map((item) {
          return Card( // Use Card for consistent styling
             color: groupValue == item
                 ? Theme.of(context).colorScheme.primary.withOpacity(0.7) // Darker purple when selected
                 : Colors.white.withOpacity(0.9), // Slightly transparent white when not selected
            elevation: groupValue == item ? 4 : 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: groupValue == item ? Colors.white : Colors.grey.shade300, width: 2)), // White border when selected
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(children: [Text(item.toString().toUpperCase(),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: groupValue == item ? Colors.white : Colors.black87 // White text when selected, black otherwise
                    ))
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
