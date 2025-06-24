// screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_screen.dart';

// A simple model for our food entries to make data handling easier
class FoodEntry {
  final String name;
  final double calories;
  final String mealType;

  FoodEntry({required this.name, required this.calories, required this.mealType});

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      name: map['food_name'] as String,
      calories: (map['calories'] as num).toDouble(),
      mealType: map['meal_type'] as String,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  List<FoodEntry> _foodEntries = [];
  double _totalCaloriesToday = 0;
  int _totalWaterToday = 0; // State for water intake
  bool _isLoading = true;
  String? _errorMessage;

  final supabase = Supabase.instance.client;
  final double _waterGoal = 3000; // Default daily water goal in ml

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Fetch profile, food, and water data in parallel
      final responses = await Future.wait([
        supabase.from('profiles').select().eq('id', userId).single(),
        supabase.from('food_diary').select().eq('user_id', userId).eq('logged_date', today),
        supabase.from('water_log').select('quantity_ml').eq('user_id', userId).eq('logged_date', today),
      ]);

      // Process profile data
      _profile = responses[0] as Map<String, dynamic>;

      // Process food data
      final foodResponse = responses[1] as List<dynamic>;
      _foodEntries = foodResponse.map((item) => FoodEntry.fromMap(item)).toList();
      _totalCaloriesToday = _foodEntries.fold(0, (sum, item) => sum + item.calories);

      // Process water data
      final waterResponse = responses[2] as List<dynamic>;
      _totalWaterToday = waterResponse.fold(0, (sum, item) => sum + (item['quantity_ml'] as int));

    } catch (e) {
      if (mounted) {
        _errorMessage = "Failed to load dashboard data. Please try again.";
        print("Dashboard Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _logWater(int quantity) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('water_log').insert({'user_id': userId, 'quantity_ml': quantity});
      _fetchDashboardData(); // Refresh the whole dashboard
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log water: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddWaterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Water'),
          content: const Text('Select the amount of water you drank.'),
          actions: [
            _buildWaterButton(250, '1 Glass'),
            _buildWaterButton(500, '1 Bottle'),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaterButton(int amount, String label) {
    return TextButton(
      child: Text(label),
      onPressed: () {
        Navigator.of(context).pop();
        _logWater(amount);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_profile?['full_name']?.split(' ')[0] ?? ''}'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildCalorieSummaryCard(theme),
                      const SizedBox(height: 24),
                      _buildWaterSummaryCard(theme), // New Water Card
                      const SizedBox(height: 24),
                      _buildTodaysMealsCard(theme),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddFoodScreen()),
          );
          if (result == true) {
            _fetchDashboardData();
          }
        },
        label: const Text('Add Meal'),
        icon: const Icon(Icons.fastfood),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildCalorieSummaryCard(ThemeData theme) {
    final calorieGoal = (_profile?['daily_calorie_goal'] as num?)?.toDouble() ?? 2000.0;
    final remaining = calorieGoal - _totalCaloriesToday;
    final progress = (_totalCaloriesToday / calorieGoal).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Calories', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
            const SizedBox(height: 16),
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary), // Red
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(remaining.toStringAsFixed(0), style: theme.textTheme.headlineMedium),
                        Text('Remaining', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Goal', calorieGoal.toStringAsFixed(0), theme),
                _buildStatColumn('Consumed', _totalCaloriesToday.toStringAsFixed(0), theme),
              ],
            )
          ],
        ),
      ),
    );
  }
  
  // NEW WIDGET for the Water Summary Card
  Widget _buildWaterSummaryCard(ThemeData theme) {
    final remaining = _waterGoal - _totalWaterToday;
    final progress = (_totalWaterToday / _waterGoal).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                 Text('Water', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
                 OutlinedButton.icon(
                   onPressed: _showAddWaterDialog,
                   icon: const Icon(Icons.add),
                   label: const Text("Log"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                 )
               ],
             ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary), // Yellow
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_totalWaterToday.toStringAsFixed(0)} ml', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_waterGoal.toStringAsFixed(0)} ml Goal', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTodaysMealsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Meals', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            if (_foodEntries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('No meals logged yet today.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else
              Column(
                children: _foodEntries.map((entry) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.mealType.toUpperCase()),
                    trailing: Text('${entry.calories.toStringAsFixed(0)} kcal', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    dense: true,
                  )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}