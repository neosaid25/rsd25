import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger('RecipeService');

  // الحصول على جميع الوصفات للمستخدم الحالي
  Future<List<Recipe>> getUserRecipes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await _supabase
          .from('recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      _logger.severe('خطأ في الحصول على الوصفات: $e');
      rethrow;
    }
  }

  // الحصول على وصفة محددة
  Future<Recipe> getRecipe(String recipeId) async {
    try {
      final response = await _supabase
          .from('recipes')
          .select()
          .eq('id', recipeId)
          .single();

      return Recipe.fromMap(response);
    } catch (e) {
      _logger.severe('خطأ في الحصول على الوصفة: $e');
      rethrow;
    }
  }

  // إضافة وصفة جديدة
  Future<Recipe> addRecipe(Recipe recipe) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final recipeData = _mapRecipeToSupabase(recipe.copyWith(userId: userId));

      await _supabase.from('recipes').insert(recipeData);

      return recipe.copyWith(userId: userId);
    } catch (e) {
      _logger.severe('خطأ في إضافة الوصفة: $e');
      rethrow;
    }
  }

  // تحديث وصفة
  Future<Recipe> updateRecipe(Recipe recipe) async {
    try {
      final recipeData = _mapRecipeToSupabase(recipe);

      await _supabase.from('recipes').update(recipeData).eq('id', recipe.id);

      return recipe;
    } catch (e) {
      _logger.severe('خطأ في تحديث الوصفة: $e');
      rethrow;
    }
  }

  // حذف وصفة
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _supabase.from('recipes').delete().eq('id', recipeId);
    } catch (e) {
      _logger.severe('خطأ في حذف الوصفة: $e');
      rethrow;
    }
  }

  // تبديل حالة المفضلة
  Future<Recipe> toggleFavorite(Recipe recipe) async {
    try {
      final updatedRecipe = recipe.copyWith(isFavorite: !recipe.isFavorite);

      await _supabase
          .from('recipes')
          .update({'is_favorite': updatedRecipe.isFavorite})
          .eq('id', recipe.id);

      return updatedRecipe;
    } catch (e) {
      _logger.severe('خطأ في تبديل حالة المفضلة: $e');
      rethrow;
    }
  }

  // الحصول على الوصفات المفضلة
  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await _supabase
          .from('recipes')
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true);

      return (response as List).map((data) => Recipe.fromMap(data)).toList();
    } catch (e) {
      _logger.severe('خطأ في الحصول على الوصفات المفضلة: $e');
      rethrow;
    }
  }

  // مساعدة لتحويل البيانات من Supabase إلى Recipe

  // مساعدة لتحويل Recipe إلى البيانات التي يمكن إدخالها في Supabase
  Map<String, dynamic> _mapRecipeToSupabase(Recipe recipe) {
    return {
      'name': recipe.name, // Changé de 'title' à 'name'
      'description': recipe.description,
      'ingredients': recipe.ingredients.map((i) => i.toMap()).toList(),
      'instructions': recipe.steps.map((s) => s.toMap()).toList(),
      'image_url': recipe.imageUrl,
      'is_favorite': recipe.isFavorite,
      'user_id': recipe.userId,
      'preparation_time': recipe.preparationTime,
      'cooking_time': recipe.cookingTime,
      'servings': recipe.servings,
      'calories': recipe.calories,
      'cost': recipe.cost,
      'categories': recipe.categories, // Changé de 'category' à 'categories'
      'created_at': recipe.createdAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
