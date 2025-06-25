// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../main.dart'; // Import for theme colors

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State for reminder toggles and times
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

  /// Loads saved notification settings from SharedPreferences.
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

  /// Updates a reminder's state and schedules or cancels the notification.
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

    // Reload settings to reflect changes immediately in the UI.
    _loadSettings();
  }

  /// Shows a time picker dialog styled to match the app theme.
  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
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
    if (picked != null && picked != initialTime) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
        height: double.infinity,
        width: double.infinity,
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
        child: SafeArea( 
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
                    _updateReminder(enabled: _breakfastReminder, time: newTime, keyPrefix: 'breakfast', notificationId: 0, mealName: 'Breakfast');
                  });
                }
              ),
              const SizedBox(height: 12),
              _buildReminderTile(
                title: 'Lunch Reminder',
                value: _lunchReminder,
                time: _lunchTime,
                onChanged: (enabled) {
                  _updateReminder(enabled: enabled, time: _lunchTime, keyPrefix: 'lunch', notificationId: 1, mealName: 'Lunch');
                },
                onTimeTap: () {
                  _selectTime(context, _lunchTime, (newTime) {
                     _updateReminder(enabled: _lunchReminder, time: newTime, keyPrefix: 'lunch', notificationId: 1, mealName: 'Lunch');
                  });
                }
              ),
              const SizedBox(height: 12),
               _buildReminderTile(
                title: 'Dinner Reminder',
                value: _dinnerReminder,
                time: _dinnerTime,
                onChanged: (enabled) {
                  _updateReminder(enabled: enabled, time: _dinnerTime, keyPrefix: 'dinner', notificationId: 2, mealName: 'Dinner');
                },
                onTimeTap: () {
                  _selectTime(context, _dinnerTime, (newTime) {
                     _updateReminder(enabled: _dinnerReminder, time: newTime, keyPrefix: 'dinner', notificationId: 2, mealName: 'Dinner');
                  });
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single reminder setting tile.
  Widget _buildReminderTile({
    required String title,
    required bool value,
    required TimeOfDay time,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTimeTap
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: GestureDetector(
            onTap: onTimeTap,
            child: Text(
              'Remind me at: ${time.format(context)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.9)),
            ),
          ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          // FIX: Add a visible color for the inactive track of the switch.
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ),
    );
  }
}
