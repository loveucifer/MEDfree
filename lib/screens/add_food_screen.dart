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
    // 1. Navigate to our new scanner screen and wait for it to return a result.
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    // 2. Check if the user cancelled or returned no code.
    if (!mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
    });

    // 3. Look up the product using the scanned barcode.
    try {
      final product = await _foodApiService.lookupProductByBarcode(barcode);
      if (product != null) {
        _showLogDialog(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product not found for this barcode.'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    final servingController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
              title: Text(product.productName),
              content: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (value != null) setDialogState(() => selectedMealType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: servingController,
                    decoration: const InputDecoration(labelText: 'Serving Size', suffixText: 'grams'),
                    keyboardType: TextInputType.number,
                  )
                ],),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                FilledButton(
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
    // The build method remains the same as before
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Food'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 16),
                const Row(children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")),
                    Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _searchResults = []; });
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResultsList())
        ],
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
      return const Center(child: Text('No results found.'));
    }
    if (_searchResults.isEmpty) {
       return const Center(child: Text('Start typing to search for a food.'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ListTile(
          title: Text(product.productName),
          subtitle: Text('${product.calories.toStringAsFixed(0)} kcal per 100g'),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () => _showLogDialog(product),
        );
      },
    );
  }
}