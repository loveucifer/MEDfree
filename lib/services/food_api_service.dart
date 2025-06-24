// lib/services/food_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_product.dart';

class FoodApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  Future<List<FoodProduct>> searchFood(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    final uri = Uri.parse('$_baseUrl/search?search_terms=$query&search_simple=1&json=1&fields=product_name_en,product_name,nutriments');
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = (data['products'] as List)
            .map((item) => FoodProduct.fromJson(item))
            .where((product) => product.isValid)
            .toList();
        return products;
      } else {
        throw Exception('Failed to load food data');
      }
    } catch (e) {
      print('Error searching for food: $e');
      throw Exception('Could not connect to the food database.');
    }
  }

  // --- NEW METHOD FOR BARCODE LOOKUP ---
  Future<FoodProduct?> lookupProductByBarcode(String barcode) async {
    if (barcode.isEmpty) {
      return null;
    }
    
    final uri = Uri.parse('$_baseUrl/product/$barcode?fields=product_name_en,product_name,nutriments');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = FoodProduct.fromJson(data['product']);
          return product.isValid ? product : null;
        } else {
          return null; // Product not found
        }
      } else {
        throw Exception('Failed to load barcode data');
      }
    } catch (e) {
      print('Error looking up barcode: $e');
      throw Exception('Could not connect to the food database.');
    }
  }
}