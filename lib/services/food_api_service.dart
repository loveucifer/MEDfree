import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:medfree/models/food_product.dart';
// Import Supabase instead of Firebase
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodApiService {
  // Get api key and app id from .env file
  final String? apiKey = dotenv.env['FOOD_API_KEY'];
  final String? appId = dotenv.env['FOOD_APP_ID'];

  // This was the problem area. It was trying to get the user when the app
  // was first loading, often before Supabase was ready.
  // By using a getter, we ensure it only runs when needed, after initialization.
  
  /// Safely gets the current Supabase user.
  /// Returns null if no user is signed in.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Searches for food using the Edamam API based on a query string.
  /// Returns a list of food products.
  Future<List<FoodProduct>> searchFood(String query) async {
    if (apiKey == null || appId == null) {
      print('API key or App ID not found in .env file');
      throw Exception('API key or App ID not found in .env file');
    }
    final url = 'https://api.edamam.com/api/food-database/v2/parser?app_id=$appId&app_key=$apiKey&ingr=$query';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns a list of 'hints', we map over them to create our products.
        if (data['hints'] != null && (data['hints'] as List).isNotEmpty) {
          final List<dynamic> hints = data['hints'];
          return hints
              .map((hint) => FoodProduct.fromJson(hint['food']))
              .toList();
        }
      }
      // If there are no results, return an empty list.
      return [];
    } catch (e) {
      print('Error searching food: $e');
      // On error, also return an empty list to prevent crashes.
      return [];
    }
  }

  /// Searches for food using the Edamam API based on a UPC barcode.
  Future<FoodProduct?> lookupProductByBarcode(String barcode) async {
    if (apiKey == null || appId == null) {
      print('API key or App ID not found in .env file');
      throw Exception('API key or App ID not found in .env file');
    }
    final url = 'https://api.edamam.com/api/food-database/v2/parser?app_id=$appId&app_key=$apiKey&upc=$barcode';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Barcode lookups usually return a single top result in 'parsed'
        if (data['parsed'] != null && (data['parsed'] as List).isNotEmpty) {
          return FoodProduct.fromJson(data['parsed'][0]['food']);
        }
      }
      return null;
    } catch (e) {
      print('Error searching barcode: $e');
      return null;
    }
  }
}
