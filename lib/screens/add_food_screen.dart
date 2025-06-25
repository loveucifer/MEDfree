// lib/screens/add_food_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_product.dart';
import '../services/food_api_service.dart';
import 'barcode_scanner_screen.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _foodApiService = FoodApiService();
  final _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  List<FoodProduct> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- UPDATED Scan Logic ---
  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final product = await _foodApiService.lookupProductByBarcode(barcode);
      if (product != null) {
        _showLogDialog(product);
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product not found for this barcode.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- Search Logic (remains the same) ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      if (query.length > 2) {
        _performSearch(query);
      } else {
        setState(() { _searchResults = []; });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await _foodApiService.searchFood(query);
      setState(() { _searchResults = results; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // --- Logging and Dialog Logic (remains the same) ---
  Future<void> _logFood(FoodProduct product, String mealType, double servingSize) async {
    final double calories = (product.calories / 100) * servingSize;
    final double protein = (product.protein / 100) * servingSize;
    final double carbs = (product.carbs / 100) * servingSize;
    final double fat = (product.fat / 100) * servingSize;

    try {
      final userId = supabase.auth.currentUser!.id;
      final foodData = {
        'user_id': userId, 'food_name': product.productName, 'calories': calories,
        'protein_g': protein, 'carbs_g': carbs, 'fat_g': fat, 'meal_type': mealType,
        'serving_size': '$servingSize g'
      };
      await supabase.from('food_diary').insert(foodData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.productName} logged!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log food: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showLogDialog(FoodProduct product) {
    String selectedMealType = 'breakfast';
    final servingController = TextEditingController(text: '100'); // Default serving size
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
              title: Text(product.productName),
              content: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calories: ${product.calories.toStringAsFixed(1)} kcal / 100g', style: const TextStyle(color: Colors.black87)), // Dark text
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: InputDecoration(
                      labelText: 'Meal Type',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Dark text for labels
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['breakfast', 'lunch', 'dinner', 'snack']
                        .map((label) => DropdownMenuItem(value: label, child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.black87)))) // Dark text for items
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => selectedMealType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: servingController,
                    decoration: InputDecoration(
                      labelText: 'Serving Size',
                      suffixText: 'grams',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Dark text for labels
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87), // Dark text for input
                  )
                ],),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton( // Changed to ElevatedButton for consistent styling
                  onPressed: () {
                    final servingSize = double.tryParse(servingController.text) ?? 100.0;
                    Navigator.of(context).pop();
                    _logFood(product, selectedMealType, servingSize);
                  },
                  child: const Text('Log Food')),
              ],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      appBar: AppBar(
        title: Text(
          'Find a Food',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom( // Override style for this specific button if needed
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color (SkyBlue)
                      foregroundColor: Theme.of(context).colorScheme.onSecondary, // White text
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(children: [
                      Expanded(child: Divider(color: Colors.black45)), // Darker divider
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR", style: TextStyle(color: Colors.black54))), // Darker text
                      Expanded(child: Divider(color: Colors.black45)), // Darker divider
                  ]),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.black54), // Darker icon
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black54), // Darker icon
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _searchResults = []; });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9), // White fill for text field
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Darker label
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]), // Lighter hint
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Darker input text
                  ),
                ],
              ),
            ),
            Expanded(child: _buildResultsList())
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: Colors.black54))); // Darker text
    }
    if (_searchResults.isEmpty) {
       return const Center(child: Text('Start typing to search for a food.', style: TextStyle(color: Colors.black54))); // Darker text
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return Card( // Wrap ListTile in Card
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(product.productName, style: const TextStyle(color: Colors.black87)), // Dark text
            subtitle: Text('${product.calories.toStringAsFixed(0)} kcal per 100g', style: const TextStyle(color: Colors.grey)), // Dark text
            trailing: const Icon(Icons.add_circle_outline, color: Colors.black54), // Darker icon
            onTap: () => _showLogDialog(product),
          ),
        );
      },
    );
  }
}
