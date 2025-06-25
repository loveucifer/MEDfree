// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/skeleton_loader.dart';
import 'add_food_screen.dart';
import 'add_exercise_screen.dart';

// Data models for entries, moved for clarity
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
  final double _waterGoal = 3000; // Example goal

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  /// Fetches all necessary data for the dashboard from Supabase.
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final responses = await Future.wait<dynamic>([
        supabase.from('profiles').select().eq('id', userId).single(),
        supabase.from('food_diary').select().eq('user_id', userId).eq('logged_date', today),
        supabase.from('water_log').select('quantity_ml').eq('user_id', userId).eq('logged_date', today),
        supabase.from('exercise_log').select().eq('user_id', userId).eq('logged_date', today),
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

      // Process exercise data
      final exerciseResponse = responses[3] as List<dynamic>;
      _exerciseEntries = exerciseResponse.map((item) => ExerciseEntry.fromMap(item)).toList();
      _totalCaloriesBurnedToday = _exerciseEntries.fold(0, (sum, item) => sum + item.caloriesBurned);

    } catch (e) {
      if (mounted) _errorMessage = "Failed to load dashboard data.";
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  /// Logs a water entry to the database.
  Future<void> _logWater(int quantity) async {
    try {
      await supabase.from('water_log').insert({'user_id': supabase.auth.currentUser!.id, 'quantity_ml': quantity});
      _fetchDashboardData(); // Refresh data after logging.
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log water: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? _buildDashboardShimmer()
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _fetchDashboardData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                        children: [
                          Text('Welcome back, ${_profile?['full_name']?.split(' ')[0] ?? 'User'}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 24),
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
        floatingActionButton: _buildActionButtons(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: const [
          Skeleton(width: 250, height: 32, radius: 8),
          SizedBox(height: 24),
          Skeleton(height: 220, radius: 20),
          SizedBox(height: 24),
          Skeleton(height: 130, radius: 20),
          SizedBox(height: 24),
          Skeleton(height: 200, radius: 20),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'log_exercise_fab',
              onPressed: () async {
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AddExerciseScreen()));
                if (result == true) _fetchDashboardData();
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Log Exercise'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: 'log_meal_fab',
              onPressed: () async {
                final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (context) => const AddFoodScreen()));
                if (result == true) _fetchDashboardData();
              },
              icon: const Icon(Icons.fastfood),
              label: const Text('Log Meal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSummaryCard(ThemeData theme) {
    final calorieGoal = (_profile?['daily_calorie_goal'] as num?)?.toDouble() ?? 2000.0;
    final netCalories = _totalCaloriesToday - _totalCaloriesBurnedToday;
    final remaining = calorieGoal - netCalories;

    return Card(
      // PASTEL COLOR ADDED
      color: const Color(0xFFE6E0F8), // Light pastel purple
      child: Padding(padding: const EdgeInsets.all(20.0), child: Column(children: [
            Text('Net Calories', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(width: 150, height: 150, child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                    value: (netCalories / calorieGoal).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)
                  ),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(remaining.toStringAsFixed(0), style: theme.textTheme.headlineMedium),
                        Text('Remaining', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                      ],),),
                ],),),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildStatColumn('Goal', calorieGoal.toStringAsFixed(0), theme),
                _buildStatColumn('Food', _totalCaloriesToday.toStringAsFixed(0), theme),
                _buildStatColumn('Burned', _totalCaloriesBurnedToday.toStringAsFixed(0), theme, color: theme.colorScheme.secondary),
              ],)
          ],),),);
  }

  Widget _buildWaterSummaryCard(ThemeData theme) {
    return Card(
      // PASTEL COLOR ADDED
      color: const Color(0xFFE0F7FA), // Light pastel blue/cyan
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: [
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
                 Text('Water', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                 OutlinedButton.icon(
                    onPressed: () => _logWater(250),
                    icon: Icon(Icons.add, color: theme.colorScheme.primary),
                    label: Text("Log", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))
                 )
               ],),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_totalWaterToday / _waterGoal).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
              borderRadius: BorderRadius.circular(6)
            ),
            const SizedBox(height: 16),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${_totalWaterToday.toStringAsFixed(0)} ml', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_waterGoal.toStringAsFixed(0)} ml Goal', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
              ],)
          ],),),);
  }

  Widget _buildTodaysMealsCard(ThemeData theme) {
    return Card(
      // PASTEL COLOR ADDED
      color: Colors.white, // Keeping this white as per the general design
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Meals', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            _foodEntries.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text('No meals logged yet.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              : Column(children: _foodEntries.map((entry) => ListTile(
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry.mealType.toUpperCase()),
                    trailing: Text('${entry.calories.toStringAsFixed(0)} kcal', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    dense: true)).toList()),
          ],),),);
  }

  Widget _buildTodaysExercisesCard(ThemeData theme) {
    return Card(
      // PASTEL COLOR ADDED
      color: Colors.white, // Keeping this white as per the general design
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today\'s Exercises', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 10),
            _exerciseEntries.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: Text('No exercises logged yet.', style: TextStyle(color: Colors.grey, fontSize: 16))))
              : Column(children: _exerciseEntries.map((entry) => ListTile(
                    title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${entry.caloriesBurned.toStringAsFixed(0)} kcal burned', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)),
                    dense: true)).toList()),
          ],),),);
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme, {Color? color}) {
    return Column(children: [
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, color: color ?? Colors.black87, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
      ],);
  }
}
