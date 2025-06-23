// lib/app/domain/models/recipe_step_model.dart

import 'package:uuid/uuid.dart';

class RecipeStep {
  final String id;
  final String description;
  final int order;

  RecipeStep({
    String? id,
    required this.description,
    required this.order,
  }) : id = id ?? const Uuid().v4();

  // Method to convert a RecipeStep to a map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'order': order,
    };
  }

  // Factory constructor for creating a RecipeStep from a map (from JSON)
  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      id: map['id'] ?? const Uuid().v4(),
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  RecipeStep copyWith({
    String? description,
    int? order,
  }) {
    return RecipeStep(
      id: this.id,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}