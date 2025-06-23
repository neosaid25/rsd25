import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:monappmealplanning/app/core/config/supabase_config.dart';

final _logger = Logger('MealPlanService');

class MealPlanService {
  final _supabase = Supabase.instance.client;

  // حفظ خطة الوجبات الأسبوعية
  Future<void> saveWeeklyPlan(
    Map<String, Map<String, List<Map<String, String>>>> weeklyPlan,
    String weekStartDate,
  ) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لحفظ خطة الوجبات");
    }

    try {
      // إنشاء معرف فريد للخطة الأسبوعية باستخدام معرف المستخدم وتاريخ بداية الأسبوع
      final String planId = '${currentUser.id}_$weekStartDate';

      // التحقق مما إذا كانت الخطة موجودة بالفعل
      final existingPlan = await _supabase
          .from(SupabaseConfig.weeklyMealPlansTable)
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (existingPlan != null) {
        // تحديث الخطة الموجودة
        await _supabase
            .from(SupabaseConfig.weeklyMealPlansTable)
            .update({
              'plan': weeklyPlan,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', planId);
      } else {
        // إنشاء خطة جديدة
        await _supabase.from(SupabaseConfig.weeklyMealPlansTable).insert({
          'id': planId,
          'user_id': currentUser.id,
          'week_start_date': weekStartDate,
          'plan': weeklyPlan,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _logger.info(
        'تم حفظ خطة الوجبات الأسبوعية بنجاح للمستخدم ${currentUser.id}',
      );
    } catch (e) {
      _logger.severe('خطأ في حفظ خطة الوجبات الأسبوعية: $e');
      throw Exception("فشل في حفظ خطة الوجبات الأسبوعية: $e");
    }
  }

  // الحصول على خطة الوجبات الأسبوعية
  Future<Map<String, Map<String, List<Map<String, String>>>>> getWeeklyPlan(
    String weekStartDate,
  ) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول للوصول إلى خطة الوجبات");
    }

    try {
      final String planId = '${currentUser.id}_$weekStartDate';

      final response = await _supabase
          .from(SupabaseConfig.weeklyMealPlansTable)
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (response != null && response['plan'] != null) {
        // تحويل البيانات من JSON إلى Map
        final Map<String, dynamic> planJson = response['plan'];
        Map<String, Map<String, List<Map<String, String>>>> result = {};

        planJson.forEach((day, meals) {
          final Map<String, dynamic> mealsMap = meals;
          Map<String, List<Map<String, String>>> dayMeals = {};

          mealsMap.forEach((mealType, mealsList) {
            // Ensure mealsList is a List of Maps
            dayMeals[mealType] = List<Map<String, String>>.from(
              (mealsList as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            );
          });

          result[day] = dayMeals;
        });

        return result;
      }

      // إذا لم يتم العثور على خطة، إرجاع خريطة فارغة
      return {};
    } catch (e) {
      _logger.severe('خطأ في جلب خطة الوجبات الأسبوعية: $e');
      throw Exception("فشل في جلب خطة الوجبات الأسبوعية: $e");
    }
  }

  // حفظ خطة الوجبات الشهرية
  Future<void> saveMonthlyPlan(
    Map<String, Map<String, List<Map<String, String>>>> monthlyPlan,
    String monthStartDate,
  ) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لحفظ خطة الوجبات");
    }

    try {
      // إنشاء معرف فريد للخطة الشهرية باستخدام معرف المستخدم وتاريخ بداية الشهر
      final String planId = '${currentUser.id}_$monthStartDate';

      // التحقق مما إذا كانت الخطة موجودة بالفعل
      final existingPlan = await _supabase
          .from(SupabaseConfig.monthlyMealPlansTable)
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (existingPlan != null) {
        // تحديث الخطة الموجودة
        await _supabase
            .from(SupabaseConfig.monthlyMealPlansTable)
            .update({
              'plan': monthlyPlan,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', planId);
      } else {
        // إنشاء خطة جديدة
        await _supabase.from(SupabaseConfig.monthlyMealPlansTable).insert({
          'id': planId,
          'user_id': currentUser.id,
          'month_start_date': monthStartDate,
          'plan': monthlyPlan,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      _logger.info(
        'تم حفظ خطة الوجبات الشهرية بنجاح للمستخدم ${currentUser.id}',
      );
    } catch (e) {
      _logger.severe('خطأ في حفظ خطة الوجبات الشهرية: $e');
      throw Exception("فشل في حفظ خطة الوجبات الشهرية: $e");
    }
  }

  // الحصول على خطة الوجبات الشهرية
  Future<Map<String, Map<String, List<Map<String, String>>>>> getMonthlyPlan(
    String monthStartDate,
  ) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول للوصول إلى خطة الوجبات");
    }

    try {
      final String planId = '${currentUser.id}_$monthStartDate';

      final response = await _supabase
          .from(SupabaseConfig.monthlyMealPlansTable)
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (response != null && response['plan'] != null) {
        // تحويل البيانات من JSON إلى Map
        final Map<String, dynamic> planJson = response['plan'];
        Map<String, Map<String, List<Map<String, String>>>> result = {};

        planJson.forEach((date, meals) {
          final Map<String, dynamic> mealsMap = meals;
          Map<String, List<Map<String, String>>> dateMeals = {};

          mealsMap.forEach((mealType, mealsList) {
            // Ensure mealsList is a List of Maps
            dateMeals[mealType] = List<Map<String, String>>.from(
              (mealsList as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            );
          });

          result[date] = dateMeals;
        });

        return result;
      }

      // إذا لم يتم العثور على خطة، إرجاع خريطة فارغة
      return {};
    } catch (e) {
      _logger.severe('خطأ في جلب خطة الوجبات الشهرية: $e');
      throw Exception("فشل في جلب خطة الوجبات الشهرية: $e");
    }
  }

  // استرجاع جميع المخططات الأسبوعية المحفوظة للمستخدم
  Future<List<Map<String, dynamic>>> getSavedWeeklyPlans() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لاسترجاع المخططات المحفوظة");
    }

    try {
      final response = await _supabase
          .from(SupabaseConfig.weeklyMealPlansTable)
          .select()
          .eq('user_id', currentUser.id)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في استرجاع المخططات الأسبوعية المحفوظة: $e');
      throw Exception("فشل في استرجاع المخططات الأسبوعية المحفوظة: $e");
    }
  }

  // استرجاع جميع المخططات الشهرية المحفوظة للمستخدم
  Future<List<Map<String, dynamic>>> getSavedMonthlyPlans() async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لاسترجاع المخططات المحفوظة");
    }

    try {
      final response = await _supabase
          .from(SupabaseConfig.monthlyMealPlansTable)
          .select()
          .eq('user_id', currentUser.id)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.severe('خطأ في استرجاع المخططات الشهرية المحفوظة: $e');
      throw Exception("فشل في استرجاع المخططات الشهرية المحفوظة: $e");
    }
  }

  // حذف مخطط أسبوعي محفوظ
  Future<void> deleteWeeklyPlan(String weekStartDate) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لحذف المخططات المحفوظة");
    }

    try {
      final String planId = '${currentUser.id}_$weekStartDate';
      await _supabase
          .from(SupabaseConfig.weeklyMealPlansTable)
          .delete()
          .eq('id', planId);

      _logger.info('تم حذف المخطط الأسبوعي بنجاح: $planId');
    } catch (e) {
      _logger.severe('خطأ في حذف المخطط الأسبوعي: $e');
      throw Exception("فشل في حذف المخطط الأسبوعي: $e");
    }
  }

  // حذف مخطط شهري محفوظ
  Future<void> deleteMonthlyPlan(String monthStartDate) async {
    final User? currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("يجب تسجيل الدخول لحذف المخططات المحفوظة");
    }

    try {
      final String planId = '${currentUser.id}_$monthStartDate';
      await _supabase
          .from(SupabaseConfig.monthlyMealPlansTable)
          .delete()
          .eq('id', planId);

      _logger.info('تم حذف المخطط الشهري بنجاح: $planId');
    } catch (e) {
      _logger.severe('خطأ في حذف المخطط الشهري: $e');
      throw Exception("فشل في حذف المخطط الشهري: $e");
    }
  }
}
