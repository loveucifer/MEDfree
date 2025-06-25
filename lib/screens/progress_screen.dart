// lib/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  List<FlSpot> _weightData = [];
  List<FlSpot> _calorieData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches chart data for weight and calories from the database.
  Future<void> _fetchChartData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final userId = supabase.auth.currentUser!.id;
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Fetch weight history
      final weightHistory = await supabase
          .from('weight_history')
          .select('weight_kg, logged_date')
          .eq('user_id', userId)
          .gte('logged_date', thirtyDaysAgo.toIso8601String())
          .order('logged_date', ascending: true);

      _weightData = weightHistory.map((row) {
          final date = DateTime.parse(row['logged_date']);
          final day = date.difference(thirtyDaysAgo).inDays.toDouble();
          return FlSpot(day, (row['weight_kg'] as num).toDouble());
      }).toList();

      // Fetch calorie history
      final foodDiary = await supabase
          .from('food_diary')
          .select('calories, logged_date')
          .eq('user_id', userId)
          .gte('logged_date', thirtyDaysAgo.toIso8601String())
          .order('logged_date', ascending: true);

      // Group calories by day
      final Map<double, double> dailyCalories = {};
      for (var row in foodDiary) {
        final date = DateTime.parse(row['logged_date']);
        final day = date.difference(thirtyDaysAgo).inDays.toDouble();
        final calories = (row['calories'] as num).toDouble();
        dailyCalories.update(day, (value) => value + calories, ifAbsent: () => calories);
      }
      _calorieData = dailyCalories.entries.map((e) => FlSpot(e.key, e.value)).toList();

    } catch(e) {
      if (mounted) _errorMessage = "Could not load progress data.";
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold is transparent to let the AppShell's gradient show through.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // The TabBar is styled to be visible on the gradient background.
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Weight'),
                Tab(text: 'Calories'),
              ],
            ),
            // The TabBarView fills the remaining space.
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 16)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChartContainer('Weight (kg) over 30 Days', _weightData, Theme.of(context).colorScheme.primary),
                        _buildChartContainer('Calories (kcal) over 30 Days', _calorieData, Theme.of(context).colorScheme.secondary),
                      ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the container for a single chart.
  Widget _buildChartContainer(String title, List<FlSpot> data, Color lineColor) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for the last 30 days.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
              const SizedBox(height: 32),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 14, // Show a label every 14 days
                        getTitlesWidget: (value, meta) {
                            final date = DateTime.now().subtract(Duration(days: 30 - value.toInt()));
                            return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat.MMMd().format(date), style: const TextStyle(fontSize: 12)));
                        }
                      )),
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(axisSide: meta.axisSide, space: 8.0, child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)));
                        },
                      )),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300, width: 1)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: lineColor.withOpacity(0.2)),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
