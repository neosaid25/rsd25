// lib/app/domain/models/ingredient_model.dart
import 'package:uuid/uuid.dart';

class Ingredient {
  final String id;
  final String name;
  final String
  quantity; // Using String for flexibility (e.g., "1", "1/2", "a pinch")
  final String unit; // e.g., "gram", "ml", "cup", "piece"
  final bool isChecked;
  final String category;

  Ingredient({
    String? id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    required this.category,
  }) : id = id ?? const Uuid().v4();

  // Method to convert an Ingredient to a map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'category': category,
    };
  }

  // Factory constructor for creating an Ingredient from a map (from JSON)
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? '',
      unit: map['unit'] ?? '',
      isChecked: map['isChecked'] ?? false,
      category: map['category'] ?? 'عام', // أضف هذا
    );
  }

  Ingredient copyWith({
    String? name,
    String? quantity,
    String? unit,
    bool? isChecked,
    String? category,
  }) {
    return Ingredient(
      id: this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      category: category ?? this.category,
    );
  }

  @override
  String toString() {
    return '$quantity $unit of $name';
  }
}
