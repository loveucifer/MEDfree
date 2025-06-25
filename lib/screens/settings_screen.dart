// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _breakfastReminder = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  bool _lunchReminder = false;
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  bool _dinnerReminder = false;
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 20, minute: 0);

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationService.requestPermissions();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _breakfastReminder = prefs.getBool('breakfastReminder') ?? false;
      _breakfastTime = TimeOfDay(
        hour: prefs.getInt('breakfastHour') ?? 8,
        minute: prefs.getInt('breakfastMinute') ?? 0,
      );
      _lunchReminder = prefs.getBool('lunchReminder') ?? false;
      _lunchTime = TimeOfDay(
        hour: prefs.getInt('lunchHour') ?? 13,
        minute: prefs.getInt('lunchMinute') ?? 0,
      );
      _dinnerReminder = prefs.getBool('dinnerReminder') ?? false;
      _dinnerTime = TimeOfDay(
        hour: prefs.getInt('dinnerHour') ?? 20,
        minute: prefs.getInt('dinnerMinute') ?? 0,
      );
    });
  }

  Future<void> _updateReminder({
    required bool enabled,
    required TimeOfDay time,
    required String keyPrefix,
    required int notificationId,
    required String mealName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${keyPrefix}Reminder', enabled);
    await prefs.setInt('${keyPrefix}Hour', time.hour);
    await prefs.setInt('${keyPrefix}Minute', time.minute);

    if (enabled) {
      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: 'Time to log your $mealName!',
        body: 'Don\'t forget to track your meal to stay on top of your goals.',
        scheduledTime: time,
      );
    } else {
      await _notificationService.cancelNotification(notificationId);
    }

    _loadSettings();
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) { // Custom builder for the time picker to inherit theme
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary, // Your app's primary color
              onPrimary: Theme.of(context).colorScheme.onPrimary, // White
              surface: Colors.white, // Background of the time picker dialog
              onSurface: Colors.black87, // Text/icon color on the time picker background
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
    if (picked != null && picked != initialTime) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      appBar: AppBar(
        title: Text(
          'Notifications & Reminders',
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildReminderTile(
              title: 'Breakfast Reminder',
              value: _breakfastReminder,
              time: _breakfastTime,
              onChanged: (enabled) {
                _updateReminder(enabled: enabled, time: _breakfastTime, keyPrefix: 'breakfast', notificationId: 0, mealName: 'Breakfast');
              },
              onTimeTap: () {
                _selectTime(context, _breakfastTime, (newTime) {
                  if (_breakfastReminder) {
                     _updateReminder(enabled: true, time: newTime, keyPrefix: 'breakfast', notificationId: 0, mealName: 'Breakfast');
                  } else {
                      setState(() => _breakfastTime = newTime);
                  }
                });
              }
            ),
            _buildReminderTile(
              title: 'Lunch Reminder',
              value: _lunchReminder,
              time: _lunchTime,
              onChanged: (enabled) {
                _updateReminder(enabled: enabled, time: _lunchTime, keyPrefix: 'lunch', notificationId: 1, mealName: 'Lunch');
              },
              onTimeTap: () {
                _selectTime(context, _lunchTime, (newTime) {
                  if (_lunchReminder) {
                     _updateReminder(enabled: true, time: newTime, keyPrefix: 'lunch', notificationId: 1, mealName: 'Lunch');
                  } else {
                      setState(() => _lunchTime = newTime);
                  }
                });
              }
            ),
             _buildReminderTile(
              title: 'Dinner Reminder',
              value: _dinnerReminder,
              time: _dinnerTime,
              onChanged: (enabled) {
                _updateReminder(enabled: enabled, time: _dinnerTime, keyPrefix: 'dinner', notificationId: 2, mealName: 'Dinner');
              },
              onTimeTap: () {
                _selectTime(context, _dinnerTime, (newTime) {
                  if (_dinnerReminder) {
                     _updateReminder(enabled: true, time: newTime, keyPrefix: 'dinner', notificationId: 2, mealName: 'Dinner');
                  } else {
                      setState(() => _dinnerTime = newTime);
                  }
                });
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile({
    required String title,
    required bool value,
    required TimeOfDay time,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTimeTap
  }) {
    return Card(
      elevation: 2,
      // Card shape and color inherited from main.dart
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Dark text
        subtitle: GestureDetector(
            onTap: onTimeTap,
            child: Text(
              'Remind me at: ${time.format(context)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary), // Uses primary color (MediumPurple)
            ),
          ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary, // Uses primary color (MediumPurple)
        ),
      ),
    );
  }
}
