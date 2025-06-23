import 'package:uuid/uuid.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get name {
    switch (this) {
      case MealType.breakfast:
        return 'فطور';
      case MealType.lunch:
        return 'غداء';
      case MealType.dinner:
        return 'عشاء';
      case MealType.snack:
        return 'وجبة خفيفة';
    }
  }
}

class MealPlanItem {
  final String id;
  final String recipeId;
  final String recipeName;
  final String recipeImageUrl;
  final DateTime date;
  final MealType
  mealType; // Consider renaming to itemType if it can be a product
  final String quantity;
  final String unit;
  final int servings;
  final bool isCompleted;

  MealPlanItem({
    String? id,
    required this.recipeId,
    required this.recipeName,
    this.recipeImageUrl = '',
    required this.date,
    required this.mealType,
    this.quantity = '1', // Default quantity
    this.unit = '', // Default unit
    this.servings = 1, // Default servings if it's a recipe
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  MealPlanItem copyWith({
    String? recipeId,
    String? recipeName,
    String? recipeImageUrl,
    DateTime? date,
    MealType? mealType,
    String? quantity,
    String? unit,
    int? servings,
    bool? isCompleted,
  }) {
    return MealPlanItem(
      id: this.id,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      recipeImageUrl: recipeImageUrl ?? this.recipeImageUrl,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      servings: servings ?? this.servings,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'recipeImageUrl': recipeImageUrl,
      'date': date.toIso8601String(),
      'mealType': mealType.index,
      'quantity': quantity,
      'unit': unit,
      'servings': servings,
      'isCompleted': isCompleted,
    };
  }

  factory MealPlanItem.fromMap(Map<String, dynamic> map) {
    return MealPlanItem(
      id: map['id'],
      recipeId: map['recipeId'],
      recipeName: map['recipeName'],
      recipeImageUrl: map['recipeImageUrl'] ?? '',
      date: DateTime.parse(map['date']),
      mealType: MealType.values[map['mealType']],
      quantity: map['quantity']?.toString() ?? '1',
      unit: map['unit']?.toString() ?? '',
      servings: map['servings'] ?? 1,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class MealPlan {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<MealPlanItem> items;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    String? id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.items,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  MealPlan copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<MealPlanItem>? items,
    String? userId,
    DateTime? updatedAt,
  }) {
    return MealPlan(
      id: this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      items: items ?? this.items,
      userId: userId ?? this.userId,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      items: List<MealPlanItem>.from(
        (map['items'] as List).map((i) => MealPlanItem.fromMap(i)),
      ),
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
