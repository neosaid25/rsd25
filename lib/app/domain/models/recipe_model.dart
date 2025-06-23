import 'package:uuid/uuid.dart';
import 'ingredient_model.dart'; // استيراد نموذج المكونات

class RecipeStep {
  final String id;
  final String description;
  final int order;

  RecipeStep({String? id, required this.description, required this.order})
    : id = id ?? const Uuid().v4();

  RecipeStep copyWith({String? description, int? order}) {
    return RecipeStep(
      id: this.id,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'description': description, 'order': order};
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      id: map['id'],
      description: map['description'],
      order: map['order'],
    );
  }
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int? preparationTime; // بالدقائق
  final int? cookingTime; // بالدقائق
  final int? servings;
  final int? calories;
  final String cost;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> categories;
  final bool isFavorite;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipe({
    String? id,
    required this.name,
    required this.description,
    this.imageUrl = '',
    this.preparationTime,
    this.cookingTime,
    this.servings,
    this.calories,
    this.cost = '',
    required this.ingredients,
    required this.steps,
    required this.categories,
    this.isFavorite = false,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? preparationTime,
    int? cookingTime,
    int? servings,
    int? calories,
    String? cost,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    List<String>? categories,
    bool? isFavorite,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      cost: cost ?? this.cost,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      categories: categories ?? this.categories,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    // Traitement spécial pour les catégories
    List<String> categoriesList = [];
    if (map['categories'] != null) {
      if (map['categories'] is String) {
        categoriesList = [map['categories']];
      } else if (map['categories'] is List) {
        categoriesList = List<String>.from(map['categories']);
      }
    }

    return Recipe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['image_url'] ?? '',
      preparationTime: map['preparation_time'],
      cookingTime: map['cooking_time'],
      servings: map['servings'],
      calories: map['calories'],
      cost: map['cost'] ?? '',
      ingredients: List<Ingredient>.from(
        (map['ingredients'] as List? ?? []).map(
          (i) => i is Map<String, dynamic>
              ? Ingredient.fromMap(i)
              : Ingredient(
                  name: i.toString(),
                  quantity: '',
                  unit: '',
                  category: '',
                ),
        ),
      ),
      steps: List<RecipeStep>.from(
        (map['instructions'] as List? ?? []).map(
          (s) => s is Map<String, dynamic>
              ? RecipeStep.fromMap(s)
              : RecipeStep(description: s.toString(), order: 0),
        ),
      ),
      categories: categoriesList,
      isFavorite: map['is_favorite'] ?? false,
      userId: map['user_id'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'cooking_time': cookingTime,
      'servings': servings,
      'calories': calories,
      'cost': cost,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'steps': steps.map((s) => s.toMap()).toList(),
      'categories': categories,
      'is_favorite': isFavorite,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
