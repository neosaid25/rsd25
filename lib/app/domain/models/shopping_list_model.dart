import 'package:uuid/uuid.dart';

class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final String unit;
  final bool isChecked;
  final String? recipeId;
  final String? recipeName;
  final String category;

  ShoppingItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isChecked = false,
    this.recipeId,
    this.recipeName,
    this.category = 'عام',
  }) : id = id ?? const Uuid().v4();

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    String? unit,
    bool? isChecked,
    String? recipeId,
    String? recipeName,
    String? category,
  }) {
    return ShoppingItem(
      id: this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'category': category,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      unit: map['unit'],
      isChecked: map['isChecked'] ?? false,
      recipeId: map['recipeId'],
      recipeName: map['recipeName'],
      category: map['category'] ?? 'عام',
    );
  }
}

class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime date;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList({
    String? id,
    required this.name,
    required this.items,
    required this.date,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ShoppingList copyWith({
    String? name,
    List<ShoppingItem>? items,
    DateTime? date,
    String? userId,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => i.toMap()).toList(),
      'date': date.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      items: List<ShoppingItem>.from(
        (map['items'] as List).map((i) => ShoppingItem.fromMap(i)),
      ),
      date: DateTime.parse(map['date']),
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}