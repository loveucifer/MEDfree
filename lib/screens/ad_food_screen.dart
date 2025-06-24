// lib/screens/add_food_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_product.dart';
import '../services/food_api_service.dart';

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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      if (query.length > 2) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await _foodApiService.searchFood(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logFood(FoodProduct product, String mealType, double servingSize) async {
    // Calculate nutrients based on serving size (API values are per 100g)
    final double calories = (product.calories / 100) * servingSize;
    final double protein = (product.protein / 100) * servingSize;
    final double carbs = (product.carbs / 100) * servingSize;
    final double fat = (product.fat / 100) * servingSize;

    try {
      final userId = supabase.auth.currentUser!.id;
      final foodData = {
        'user_id': userId,
        'food_name': product.productName,
        'calories': calories,
        'protein_g': protein,
        'carbs_g': carbs,
        'fat_g': fat,
        'meal_type': mealType,
        'serving_size': '$servingSize g'
      };

      await supabase.from('food_diary').insert(foodData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.productName} logged!'),
          backgroundColor: Colors.green,
        ));
        // Pop back to dashboard and signal a refresh
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log food: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showLogDialog(FoodProduct product) {
    String selectedMealType = 'breakfast';
    final servingController = TextEditingController(text: '100'); // Default serving size

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
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
                        .map((label) => DropdownMenuItem(
                              value: label,
                              child: Text(label.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedMealType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: servingController,
                    decoration: const InputDecoration(
                      labelText: 'Serving Size',
                      suffixText: 'grams',
                    ),
                    keyboardType: TextInputType.number,
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final servingSize = double.tryParse(servingController.text) ?? 100.0;
                    Navigator.of(context).pop(); // Close dialog first
                    _logFood(product, selectedMealType, servingSize);
                  },
                  child: const Text('Log Food'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Apple, Chicken breast...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _buildResultsList(),
          )
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
          onTap: () {
            _showLogDialog(product);
          },
        );
      },
    );
  }
}