// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_food_screen.dart';
import 'add_exercise_screen.dart';
import 'profile_screen.dart';


// Models for our data
class FoodEntry {
  final String name;
  final double calories;
  final String mealType;
  FoodEntry({required this.name, required this.calories, required this.mealType});
  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
        name: map['food_name'] as String,
        calories: (map['calories'] as num).toDouble(),
        mealType: map['meal_type'] as String,
      );
}

class ExerciseEntry {
    final String name;
    final double caloriesBurned;
    ExerciseEntry({required this.name, required this.caloriesBurned});
    factory ExerciseEntry.fromMap(Map<String, dynamic> map) => ExerciseEntry(
        name: map['exercise_name'] as String,
        caloriesBurned: (map['calories_burned'] as num).toDouble(),
    );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  List<FoodEntry> _foodEntries = [];
  List<ExerciseEntry> _exerciseEntries = [];
  double _totalCaloriesToday = 0;
  double _totalCaloriesBurnedToday = 0;
  int _totalWaterToday = 0;
  bool _isLoading = true;
  String? _errorMessage;

  final supabase = Supabase.instance.client;
  final double _waterGoal = 3000;

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

      final responses = await Future.wait([
        supabase.from('profiles').select().eq('id', userId).single(),
        supabase.from('food_diary').select().eq('user_id', userId).eq('logged_date', today),
        supabase.from('water_log').select('quantity_ml').eq('user_id', userId).eq('logged_date', today),
        supabase.from('exercise_log').select().eq('user_id', userId).eq('logged_date', today),
      ]);

      _profile = responses[0] as Map<String, dynamic>;

      final foodResponse = responses[1] as List;
      _foodEntries = foodResponse.map((item) => FoodEntry.fromMap(item)).toList();
      _totalCaloriesToday = _foodEntries.fold(0, (sum, item) => sum + item.calories);

      final waterResponse = responses[2] as List;
      _totalWaterToday = waterResponse.fold(0, (sum, item) => sum + (item['quantity_ml'] as int));

      final exerciseResponse = responses[3] as List;
      _exerciseEntries = exerciseResponse.map((item) => ExerciseEntry.fromMap(item)).toList();
      _totalCaloriesBurnedToday = _exerciseEntries.fold(0, (sum, item) => sum + item.caloriesBurned);

    } catch (e) {
      if (mounted) _errorMessage = "Failed to load dashboard data. Please try again.";
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _logWater(int quantity) async {
    try {
      await supabase.from('water_log').insert({'user_id': supabase.auth.currentUser!.id, 'quantity_ml': quantity});
      _fetchDashboardData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log water: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddWaterDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Add Water'),
          content: const Text('Select the amount of water you drank.'),
          actions: [
            _buildWaterButton(250, '1 Glass'),
            _buildWaterButton(500, '1 Bottle'),
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          ],
        ));
  }

  Widget _buildWaterButton(int amount, String label) => TextButton(
      child: Text(label),
      onPressed: () {
        Navigator.of(context).pop();
        _logWater(amount);
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // REMOVED Scaffold and AppBar from here. The AppShell provides it.
    return Scaffold(
        appBar: AppBar(
        title: Text('Welcome, ${_profile?['full_name']?.split(' ')[0] ?? ''}'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
            IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () async {
                    final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                    if (result == true) {
                    _fetchDashboardData();
                    }
                },
                tooltip: 'Profile',
            ),
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => supabase.auth.signOut(),
                tooltip: 'Sign Out'
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Add padding for FAB
                    children: [
                      _buildCalorieSummaryCard(theme),
                      const SizedBox(height: 24),
                      _buildWaterSummaryCard(theme),
                      const SizedBox(height: 24),
                      _buildTodaysMealsCard(theme),
                      const SizedBox(height: 24),
                      _buildTodaysExercisesCard(theme),
                    ],
                  ),
                ),
        floatingActionButton: _buildSpeedDialFab(),
    );
  }

  // ALL THE _build... WIDGETS (like _buildCalorieSummaryCard) remain exactly the same as the previous step
  Widget _buildCalorieSummaryCard(ThemeData theme) {
    final calorieGoal = (_profile?['daily_calorie_goal'] as num?)?.toDouble() ?? 2000.0;
    // Updated calculation
    final netCalories = _totalCaloriesToday - _totalCaloriesBurnedToday;
    final remaining = calorieGoal - netCalories;
    final progress = (netCalories / calorieGoal).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shadowColor: Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Net Calories', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
            const SizedBox(height: 16),
            SizedBox(
              width: 150, height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: progress, strokeWidth: 12, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(remaining.toStringAsFixed(0), style: theme.textTheme.headlineMedium),
                        Text('Remaining', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                      ],),),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildStatColumn('Goal', calorieGoal.toStringAsFixed(0), theme),
                _buildStatColumn('Food', _totalCaloriesToday.toStringAsFixed(0), theme),
                _buildStatColumn('Burned', _totalCaloriesBurnedToday.toStringAsFixed(0), theme, color: theme.colorScheme.secondary),
              ],)
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSummaryCard(ThemeData theme) {
     final progress = (_totalWaterToday / _waterGoal).clamp(0.0, 1.0);
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                 Text('Water', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
                 OutlinedButton.icon(onPressed: _showAddWaterDialog, icon: const Icon(Icons.add), label: const Text("Log"),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.secondary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),)
               ],),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary), borderRadius: BorderRadius.circular(6)),
            const SizedBox(height: 16),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_totalWaterToday.toStringAsFixed(0)} ml', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_waterGoal.toStringAsFixed(0)} ml Goal', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
              ],)
          ],),
      ),
    );
  }

  Widget _buildTodaysMealsCard(ThemeData theme) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Meals', style: theme.textTheme.headlineSmall), const SizedBox(height: 10),
            _foodEntries.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('No meals logged yet today.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              : Column(children: _foodEntries.map((entry) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.mealType.toUpperCase()),
                    trailing: Text('${entry.calories.toStringAsFixed(0)} kcal', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    dense: true)).toList()),
          ],),
      ),
    );
  }

  // NEW WIDGET for showing today's logged exercises
  Widget _buildTodaysExercisesCard(ThemeData theme) {
    return Card(
      elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Exercises', style: theme.textTheme.headlineSmall), const SizedBox(height: 10),
            _exerciseEntries.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('No exercises logged yet today.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              : Column(children: _exerciseEntries.map((entry) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${entry.caloriesBurned.toStringAsFixed(0)} kcal burned', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                    dense: true)).toList()),
          ],),
      ),
    );
  }


  Widget _buildStatColumn(String label, String value, ThemeData theme, {Color? color}) {
    return Column(children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20, color: color ?? Colors.black87)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
      ],);
  }

  // NEW Speed Dial Floating Action Button
  Widget _buildSpeedDialFab() {
    return Wrap(
      direction: Axis.vertical,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 12.0,
      children: <Widget>[
        _buildFabChild(
          onPressed: () async {
            final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AddExerciseScreen()));
            if (result == true) _fetchDashboardData();
          },
          label: 'Log Exercise',
          icon: Icons.fitness_center,
        ),
        _buildFabChild(
          onPressed: () async {
            final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AddFoodScreen()));
            if (result == true) _fetchDashboardData();
          },
          label: 'Log Meal',
          icon: Icons.fastfood,
        ),
      ],
    );
  }

  Widget _buildFabChild({required VoidCallback onPressed, required String label, required IconData icon}) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(icon),
      heroTag: null, // Important: each FAB needs a unique or null heroTag
    );
  }

}