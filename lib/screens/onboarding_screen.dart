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
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: _pageController.hasClients && _pageController.page?.round() != 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              )
            : null,
      ),
      body: PageView(
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
    return _buildPage(title: title, child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: hint),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
  
  Widget _buildDatePage(String title, Function(BuildContext) pickDate) {
    return _buildPage(title: title, child: GestureDetector(
        onTap: () => pickDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
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
      title: title, isFinalPage: isFinalPage,
      child: Column(
        children: items.map((item) {
          return Card(
             color: groupValue == item ? Theme.of(context).colorScheme.secondary.withOpacity(0.3) : Colors.white,
            elevation: groupValue == item ? 4 : 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: groupValue == item ? Theme.of(context).colorScheme.primary : Colors.grey.shade300, width: 2)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: InkWell(
              onTap: () => onChanged(item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(children: [Text(item.toString().toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: groupValue == item ? Theme.of(context).colorScheme.primary : Colors.black87))]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}