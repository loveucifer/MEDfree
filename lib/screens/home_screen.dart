// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/skeleton_loader.dart';
import 'add_food_screen.dart';
import 'add_exercise_screen.dart';
import 'settings_screen.dart'; // Import SettingsScreen here for the FAB


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

  // --- REVISED AND CORRECTED DATA FETCHING METHOD ---
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    // Don't set isLoading here to allow shimmer to show without a "flash"
    // setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Fetch profile data
      final profileResponse = await supabase.from('profiles').select().eq('id', userId).single();
      _profile = profileResponse;

      // Fetch today's food entries
      final foodResponse = await supabase.from('food_diary').select().eq('user_id', userId).eq('logged_date', today);
      _foodEntries = foodResponse.map((item) => FoodEntry.fromMap(item)).toList();
      _totalCaloriesToday = _foodEntries.fold(0, (sum, item) => sum + item.calories);

      // Fetch today's water entries
      final waterResponse = await supabase.from('water_log').select('quantity_ml').eq('user_id', userId).eq('logged_date', today);
      _totalWaterToday = waterResponse.fold(0, (sum, item) => sum + (item['quantity_ml'] as int));

      // Fetch today's exercise entries
      final exerciseResponse = await supabase.from('exercise_log').select().eq('user_id', userId).eq('logged_date', today);
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
    return Scaffold(
        // Set scaffold background to transparent to allow the Container with gradient to show
        backgroundColor: Colors.transparent,
        // AppBar is now managed by AppShell, removed from here
        body: Container( // Wrap body in a Container for the background gradient
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
              ? _buildDashboardShimmer()
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : RefreshIndicator(
                      onRefresh: _fetchDashboardData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        children: [
                          Text('Welcome back, ${_profile?['full_name']?.split(' ')[0] ?? ''}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal, color: Colors.black87)),
                          const SizedBox(height: 16),
                          _buildCalorieSummaryCard(Theme.of(context)),
                          const SizedBox(height: 24),
                          _buildWaterSummaryCard(Theme.of(context)),
                          const SizedBox(height: 24),
                          _buildTodaysMealsCard(Theme.of(context)),
                          const SizedBox(height: 24),
                          _buildTodaysExercisesCard(Theme.of(context)),
                        ],
                      ),
                    ),
        ),
        floatingActionButton: _buildSpeedDialFab(),
    );
  }


  Widget _buildDashboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          const Skeleton(width: 250, height: 32),
          const SizedBox(height: 16),
          // Calorie Card Skeleton
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)
            ),
            child: const Column(
              children: [
                Skeleton(width: 120, height: 28),
                SizedBox(height: 16),
                Skeleton(width: 150, height: 150, radius: 75), // Circle
                SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Column(children: [Skeleton(width: 60, height: 24), SizedBox(height: 4), Skeleton(width: 40, height: 18)]),
                    Column(children: [Skeleton(width: 60, height: 24), SizedBox(height: 4), Skeleton(width: 40, height: 18)]),
                    Column(children: [Skeleton(width: 60, height: 24), SizedBox(height: 4), Skeleton(width: 40, height: 18)]),
                ],)
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Water and List Card Skeletons
          const Skeleton(height: 130),
          const SizedBox(height: 24),
          const Skeleton(height: 200),
        ],
      ),
    );
  }

  Widget _buildCalorieSummaryCard(ThemeData theme) {
    final calorieGoal = (_profile?['daily_calorie_goal'] as num?)?.toDouble() ?? 2000.0;
    final netCalories = _totalCaloriesToday - _totalCaloriesBurnedToday;
    final remaining = calorieGoal - netCalories;
    final progress = (netCalories / calorieGoal).clamp(0.0, 1.0);
    return Card(
      elevation: 4, shadowColor: Colors.grey.withOpacity(0.2), // Use a more neutral shadow
      child: Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
            Text('Net Calories', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
            const SizedBox(height: 16),
            SizedBox(width: 150, height: 150, child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(value: progress, strokeWidth: 12, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)), // Uses primary color (MediumPurple)
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(remaining.toStringAsFixed(0), style: theme.textTheme.headlineMedium),
                        Text('Remaining', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                      ],),),
                ],),),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildStatColumn('Goal', calorieGoal.toStringAsFixed(0), theme),
                _buildStatColumn('Food', _totalCaloriesToday.toStringAsFixed(0), theme),
                _buildStatColumn('Burned', _totalCaloriesBurnedToday.toStringAsFixed(0), theme, color: theme.colorScheme.secondary), // Uses secondary color (SkyBlue)
              ],)
          ],),),);
  }

  Widget _buildWaterSummaryCard(ThemeData theme) {
     final progress = (_totalWaterToday / _waterGoal).clamp(0.0, 1.0);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                 Text('Water', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.normal)),
                 OutlinedButton.icon(
                    onPressed: _showAddWaterDialog,
                    icon: Icon(Icons.add, color: theme.colorScheme.secondary), // Icon color matches secondary
                    label: Text("Log", style: TextStyle(color: theme.colorScheme.secondary)), // Text color matches secondary
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.secondary), // Border color matches secondary
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                    ),
                 )
               ],),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary), borderRadius: BorderRadius.circular(6)), // Uses secondary color (SkyBlue)
            const SizedBox(height: 16),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_totalWaterToday.toStringAsFixed(0)} ml', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_waterGoal.toStringAsFixed(0)} ml Goal', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
              ],)
          ],),),);
  }

  Widget _buildTodaysMealsCard(ThemeData theme) {
    return Card(
      elevation: 2,
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
                    trailing: Text('${entry.calories.toStringAsFixed(0)} kcal', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)), // Uses primary color (MediumPurple)
                    dense: true)).toList()),
          ],),),);
  }

  Widget _buildTodaysExercisesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Exercises', style: theme.textTheme.headlineSmall), const SizedBox(height: 10),
            _exerciseEntries.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('No exercises logged yet today.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              : Column(children: _exerciseEntries.map((entry) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${entry.caloriesBurned.toStringAsFixed(0)} kcal burned', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)), // Uses secondary color (SkyBlue)
                    dense: true)).toList()),
          ],),),);
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme, {Color? color}) {
    return Column(children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20, color: color ?? Colors.black87)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
      ],);
  }

  Widget _buildSpeedDialFab() {
    return Wrap(direction: Axis.vertical, crossAxisAlignment: WrapCrossAlignment.end, spacing: 12.0, children: <Widget>[
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
      ],);
  }

  Widget _buildFabChild({required VoidCallback onPressed, required String label, required IconData icon}) {
    return FloatingActionButton.extended(onPressed: onPressed, label: Text(label), icon: Icon(icon), heroTag: null);
  }
}
