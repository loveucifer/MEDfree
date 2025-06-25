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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    setState(() { _isLoading = true; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final formatter = DateFormat('yyyy-MM-dd');

      // Fetch weight history
      final weightHistory = await supabase
          .from('weight_history')
          .select('weight_kg, logged_date')
          .eq('user_id', userId)
          .gte('logged_date', formatter.format(thirtyDaysAgo))
          .order('logged_date', ascending: true);

      _weightData = weightHistory.map((row) {
          final date = DateTime.parse(row['logged_date']);
          final day = date.difference(thirtyDaysAgo).inDays.toDouble();
          return FlSpot(day, row['weight_kg'].toDouble());
      }).toList();

      // Fetch calorie history
      final foodDiary = await supabase
          .from('food_diary')
          .select('calories, logged_date')
          .eq('user_id', userId)
          .gte('logged_date', formatter.format(thirtyDaysAgo))
          .order('logged_date', ascending: true);

      final Map<double, double> dailyCalories = {};
      for (var row in foodDiary) {
        final date = DateTime.parse(row['logged_date']);
        final day = date.difference(thirtyDaysAgo).inDays.toDouble();
        dailyCalories.update(day, (value) => value + row['calories'], ifAbsent: () => row['calories'].toDouble());
      }
      _calorieData = dailyCalories.entries.map((e) => FlSpot(e.key, e.value)).toList();

    } catch(e) {
      // Handle error
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      extendBodyBehindAppBar: true, // Allow body to extend behind app bar
      appBar: AppBar(
        title: Text(
          'Your Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white), // White text for app bar
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // No shadow
        foregroundColor: Colors.white, // Default icon/text color for app bar
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // White label for selected tab
          unselectedLabelColor: Colors.white70, // Lighter white for unselected
          indicatorColor: Colors.white, // White indicator
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Calories'),
          ],
        ),
      ),
      body: Container( // Wrap body in a Container for the gradient background
        width: double.infinity, // Ensure it fills width
        height: double.infinity, // Ensure it fills height
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
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChartContainer('Weight (kg)', _weightData, Theme.of(context).colorScheme.primary),
                _buildChartContainer('Calories (kcal)', _calorieData, Theme.of(context).colorScheme.secondary),
              ],
          ),
      ),
    );
  }

  Widget _buildChartContainer(String title, List<FlSpot> data, Color lineColor) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for the last 30 days.', style: TextStyle(color: Colors.black54))); // Darker text for visibility
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card( // Wrap chart in a Card to match the theme
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall), // Uses default black text for card
              const SizedBox(height: 32),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                            // Shows dates for start, middle, and end of the 30-day period
                            if (value.toInt() == 0 || value.toInt() == 15 || value.toInt() == 30) {
                                final date = DateTime.now().subtract(Duration(days: 30 - value.toInt()));
                                return SideTitleWidget(axisSide: meta.axisSide, child: Text(DateFormat.MMMd().format(date), style: const TextStyle(color: Colors.black87))); // Darker text for axis labels
                            }
                            return const Text('');
                        }
                      )),
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString(), style: const TextStyle(color: Colors.black87))); // Darker text for axis labels
                        },
                      )),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade400, width: 1)), // Lighter border color
                    lineBarsData: [
                      LineChartBarData(
                        spots: data,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 5,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: lineColor.withOpacity(0.3)),
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
