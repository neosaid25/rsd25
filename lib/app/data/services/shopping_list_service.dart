import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:monappmealplanning/app/domain/models/shopping_list_model.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/domain/models/ingredient_model.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';
import 'package:monappmealplanning/app/data/services/meal_plan_service.dart';

class ShoppingListService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger('ShoppingListService');
  final RecipeService _recipeService = RecipeService();
  final MealPlanService _mealPlanService = MealPlanService();

  // إنشاء قائمة تسوق من خطة أسبوعية
  Future<List<ShoppingItem>> generateShoppingListFromWeeklyPlan(
    String weekStartDate,
  ) async {
    try {
      _logger.info('بدء إنشاء قائمة التسوق للأسبوع: $weekStartDate');

      // الحصول على الخطة الأسبوعية
      final weeklyPlan = await _mealPlanService.getWeeklyPlan(weekStartDate);
      
      // جمع جميع أسماء الوصفات من الخطة
      final Set<String> recipeNames = {};
      weeklyPlan.forEach((day, dayMeals) {
        dayMeals.forEach((mealType, meals) {
          for (var meal in meals) {
            if (meal['name'] != null && meal['name']!.isNotEmpty) {
              recipeNames.add(meal['name']!);
            }
          }
        });
      });

      _logger.info('تم العثور على ${recipeNames.length} وصفة في الخطة');

      // الحصول على جميع الوصفات للمستخدم
      final allRecipes = await _recipeService.getUserRecipes();
      
      // تصفية الوصفات المطلوبة
      final requiredRecipes = allRecipes.where((recipe) => 
        recipeNames.contains(recipe.name)
      ).toList();

      _logger.info('تم العثور على ${requiredRecipes.length} وصفة مطابقة');

      // استخراج المكونات وتجميعها
      final Map<String, ShoppingItem> consolidatedItems = {};

      for (var recipe in requiredRecipes) {
        for (var ingredient in recipe.ingredients) {
          final key = '${ingredient.name}_${ingredient.unit}';
          
          if (consolidatedItems.containsKey(key)) {
            // دمج الكميات إذا كانت رقمية
            final existingItem = consolidatedItems[key]!;
            final existingQuantity = double.tryParse(existingItem.quantity) ?? 0;
            final newQuantity = double.tryParse(ingredient.quantity) ?? 0;
            
            if (existingQuantity > 0 && newQuantity > 0) {
              consolidatedItems[key] = existingItem.copyWith(
                quantity: (existingQuantity + newQuantity).toString(),
              );
            } else {
              // إذا لم تكن الكميات رقمية، اجمعها كنص
              consolidatedItems[key] = existingItem.copyWith(
                quantity: '${existingItem.quantity} + ${ingredient.quantity}',
              );
            }
          } else {
            consolidatedItems[key] = ShoppingItem(
              name: ingredient.name,
              quantity: ingredient.quantity,
              unit: ingredient.unit,
              category: ingredient.category.isEmpty ? 'عام' : ingredient.category,
              recipeId: recipe.id,
              recipeName: recipe.name,
            );
          }
        }
      }

      final shoppingList = consolidatedItems.values.toList();
      _logger.info('تم إنشاء قائمة تسوق تحتوي على ${shoppingList.length} عنصر');

      return shoppingList;
    } catch (e) {
      _logger.severe('خطأ في إنشاء قائمة التسوق: $e');
      rethrow;
    }
  }

  // إنشاء قائمة تسوق من خطة شهرية
  Future<List<ShoppingItem>> generateShoppingListFromMonthlyPlan(
    String monthStartDate,
  ) async {
    try {
      _logger.info('بدء إنشاء قائمة التسوق للشهر: $monthStartDate');

      // الحصول على الخطة الشهرية
      final monthlyPlan = await _mealPlanService.getMonthlyPlan(monthStartDate);
      
      // جمع جميع أسماء الوصفات من الخطة
      final Set<String> recipeNames = {};
      monthlyPlan.forEach((day, dayMeals) {
        dayMeals.forEach((mealType, meals) {
          for (var meal in meals) {
            if (meal['name'] != null && meal['name']!.isNotEmpty) {
              recipeNames.add(meal['name']!);
            }
          }
        });
      });

      _logger.info('تم العثور على ${recipeNames.length} وصفة في الخطة الشهرية');

      // الحصول على جميع الوصفات للمستخدم
      final allRecipes = await _recipeService.getUserRecipes();
      
      // تصفية الوصفات المطلوبة
      final requiredRecipes = allRecipes.where((recipe) => 
        recipeNames.contains(recipe.name)
      ).toList();

      // استخراج المكونات وتجميعها (نفس المنطق كما في الخطة الأسبوعية)
      final Map<String, ShoppingItem> consolidatedItems = {};

      for (var recipe in requiredRecipes) {
        for (var ingredient in recipe.ingredients) {
          final key = '${ingredient.name}_${ingredient.unit}';
          
          if (consolidatedItems.containsKey(key)) {
            final existingItem = consolidatedItems[key]!;
            final existingQuantity = double.tryParse(existingItem.quantity) ?? 0;
            final newQuantity = double.tryParse(ingredient.quantity) ?? 0;
            
            if (existingQuantity > 0 && newQuantity > 0) {
              consolidatedItems[key] = existingItem.copyWith(
                quantity: (existingQuantity + newQuantity).toString(),
              );
            } else {
              consolidatedItems[key] = existingItem.copyWith(
                quantity: '${existingItem.quantity} + ${ingredient.quantity}',
              );
            }
          } else {
            consolidatedItems[key] = ShoppingItem(
              name: ingredient.name,
              quantity: ingredient.quantity,
              unit: ingredient.unit,
              category: ingredient.category.isEmpty ? 'عام' : ingredient.category,
              recipeId: recipe.id,
              recipeName: recipe.name,
            );
          }
        }
      }

      final shoppingList = consolidatedItems.values.toList();
      _logger.info('تم إنشاء قائمة تسوق شهرية تحتوي على ${shoppingList.length} عنصر');

      return shoppingList;
    } catch (e) {
      _logger.severe('خطأ في إنشاء قائمة التسوق الشهرية: $e');
      rethrow;
    }
  }

  // حفظ قائمة التسوق في قاعدة البيانات
  Future<void> saveShoppingList(ShoppingList shoppingList) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final data = {
        'id': shoppingList.id,
        'name': shoppingList.name,
        'items': shoppingList.items.map((item) => item.toMap()).toList(),
        'date': shoppingList.date.toIso8601String(),
        'user_id': userId,
        'created_at': shoppingList.createdAt.toIso8601String(),
        'updated_at': shoppingList.updatedAt.toIso8601String(),
      };

      await _supabase.from('shopping_lists').insert(data);
      _logger.info('تم حفظ قائمة التسوق بنجاح');
    } catch (e) {
      _logger.severe('خطأ في حفظ قائمة التسوق: $e');
      rethrow;
    }
  }

  // الحصول على قوائم التسوق المحفوظة
  Future<List<ShoppingList>> getSavedShoppingLists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await _supabase
          .from('shopping_lists')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((data) => ShoppingList.fromMap(data)).toList();
    } catch (e) {
      _logger.severe('خطأ في الحصول على قوائم التسوق: $e');
      rethrow;
    }
  }
}
