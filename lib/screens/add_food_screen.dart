// lib/screens/add_food_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_product.dart';
import '../services/food_api_service.dart';
import 'barcode_scanner_screen.dart';
import '../main.dart'; // Import for theme colors

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

  /// Navigates to the barcode scanner and handles the result.
  Future<void> _scanBarcode() async {
    // Hide the keyboard if it's open
    FocusScope.of(context).unfocus();
    
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (!mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _searchResults = []; });

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
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  /// Debounces search input to avoid excessive API calls.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      if (query.length > 2) {
        _performSearch(query);
      } else {
        setState(() { _searchResults = []; });
      }
    });
  }

  /// Performs a food search using the FoodApiService.
  Future<void> _performSearch(String query) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final results = await _foodApiService.searchFood(query);
      setState(() { _searchResults = results; });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if(mounted) setState(() { _isLoading = false; });
    }
  }

  /// Logs the selected food item to the database.
  Future<void> _logFood(FoodProduct product, String mealType, double servingSize) async {
    // Nutrients are per 100g, so we calculate based on serving size.
    final double calories = (product.calories / 100) * servingSize;
    final double protein = (product.protein / 100) * servingSize;
    final double carbs = (product.carbs / 100) * servingSize;
    final double fat = (product.fat / 100) * servingSize;

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('food_diary').insert({
        'user_id': userId, 'food_name': product.productName, 'calories': calories,
        'protein_g': protein, 'carbs_g': carbs, 'fat_g': fat, 'meal_type': mealType,
        'serving_size': '$servingSize g'
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.productName} logged!'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop(true); // Pop and signal a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log food: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Shows the dialog to confirm and log a food item.
  void _showLogDialog(FoodProduct product) {
    String selectedMealType = 'breakfast';
    final servingController = TextEditingController(text: '100');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.productName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calories: ${product.calories.toStringAsFixed(1)} kcal / 100g'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedMealType,
              decoration: const InputDecoration(labelText: 'Meal Type'),
              items: ['breakfast', 'lunch', 'dinner', 'snack']
                  .map((label) => DropdownMenuItem(value: label, child: Text(label.toUpperCase())))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedMealType = value;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: servingController,
              decoration: const InputDecoration(labelText: 'Serving Size', suffixText: 'grams'),
              keyboardType: TextInputType.number,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final servingSize = double.tryParse(servingController.text) ?? 100.0;
              Navigator.of(context).pop(); // Close dialog
              _logFood(product, selectedMealType, servingSize);
            },
            child: const Text('Log Food'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Find a Food'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MEDfreeApp.primaryColor, MEDfreeApp.secondaryColor],
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
                  // Prominently styled "Scan Barcode" button.
                  ElevatedButton.icon(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(children: [
                      Expanded(child: Divider(color: Colors.white70)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR", style: TextStyle(color: Colors.white))),
                      Expanded(child: Divider(color: Colors.white70)),
                  ]),
                  const SizedBox(height: 16),
                  // Styled search field.
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black54),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
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

  /// Builds the list of search results.
  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)));
    }
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: Colors.white70)));
    }
    if (_searchResults.isEmpty) {
       return const Center(child: Text('Start typing or scan a barcode.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${product.calories.toStringAsFixed(0)} kcal per 100g'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => _showLogDialog(product),
          ),
        );
      },
    );
  }
}
