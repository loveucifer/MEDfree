// lib/models/food_product.dart

class FoodProduct {
  final String productName;
  final double calories; // Per 100g
  final double protein;  // Per 100g
  final double carbs;    // Per 100g
  final double fat;      // Per 100g

  FoodProduct({
    required this.productName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};
    
    // Helper to safely parse numeric values from various types
    double safeParse(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return FoodProduct(
      productName: json['product_name_en'] ?? json['product_name'] ?? 'Unknown Product',
      calories: safeParse(nutriments['energy-kcal_100g']),
      protein: safeParse(nutriments['proteins_100g']),
      carbs: safeParse(nutriments['carbohydrates_100g']),
      fat: safeParse(nutriments['fat_100g']),
    );
  }

  // A simple check to see if the product has usable data
  bool get isValid => calories > 0 && productName != 'Unknown Product';
}