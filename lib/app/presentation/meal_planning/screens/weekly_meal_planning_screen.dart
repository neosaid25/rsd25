import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لتنسيق التاريخ
import 'package:monappmealplanning/app/domain/models/recipe_model.dart'; // لاستيراد نموذج الوصفة
import 'package:monappmealplanning/app/data/services/recipe_service.dart'; // لخدمة الوصفات
import 'package:monappmealplanning/app/data/services/meal_plan_service.dart'; // لخدمة خطة الوجبات
import 'package:monappmealplanning/app/presentation/recipes/screens/my_recipes_screen.dart'; // لشاشة وصفاتي
import 'package:monappmealplanning/app/presentation/recipes/screens/add_recipe_screen.dart'; // لشاشة إضافة وصفة
import 'package:pdf/pdf.dart' as pdf_lib; // لإنشاء PDF
import 'package:pdf/widgets.dart' as pw; // لويدجت PDF
import 'package:path_provider/path_provider.dart'; // للحصول على مسار الدليل المؤقت
import 'package:open_file/open_file.dart'; // لفتح الملفات
import 'dart:io'; // لعمليات الملفات

// شاشة تخطيط الوجبات الأسبوعي
class WeeklyMealPlanningScreen extends StatefulWidget {
  // تاريخ بداية الأسبوع الأولي (اختياري، للتحرير)
  final String? initialWeekStartDate;

  const WeeklyMealPlanningScreen({Key? key, this.initialWeekStartDate})
    : super(key: key);

  @override
  State<WeeklyMealPlanningScreen> createState() =>
      _WeeklyMealPlanningScreenState();
}

class _WeeklyMealPlanningScreenState extends State<WeeklyMealPlanningScreen>
    with TickerProviderStateMixin {
  // خدمة خطة الوجبات للتعامل مع البيانات (الحفظ والتحميل)
  final MealPlanService _mealPlanService = MealPlanService();

  // هيكل بيانات لتخزين وجبات الأسبوع
  // يتمثل في خريطة للتاريخ (بصيغة سلسلة نصية) وكل يوم يحتوي على خريطة لأنواع الوجبات
  // وكل نوع وجبة يحتوي على قائمة من الخرائط التي تمثل الوجبات (اسم، كمية، وحدة)
  late Map<String, Map<String, List<Map<String, String>>>> _weeklyMeals;

  // حالة التحميل للعرض المؤشر
  bool _isLoading = true;
  // تاريخ بداية الأسبوع الحالي
  String _weekStartDate = '';
  // تاريخ أول يوم في الأسبوع المحدد (ككائن DateTime)
  late DateTime _currentWeekFirstDay;
  // متحكم TabBar
  late TabController _tabController;

  // أيام الأسبوع باللغة العربية
  final List<String> _weekDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  // متغيرات حالة لحوار نسخ اليوم
  DateTime? _sourceDateForCopyDialog;
  DateTime? _targetDateForCopyDialog;

  @override
  void initState() {
    super.initState();

    // تهيئة متحكم التبويب بعدد أيام الأسبوع
    _tabController = TabController(length: _weekDays.length, vsync: this);

    // تحديد تاريخ بداية الأسبوع
    if (widget.initialWeekStartDate != null) {
      // إذا تم تمرير تاريخ بداية أسبوع أولي (حالة تعديل)
      _weekStartDate = widget.initialWeekStartDate!;
      // تحليل التاريخ وتعيينه كأول يوم في الأسبوع الحالي
      _currentWeekFirstDay = DateFormat('yyyy-MM-dd').parse(_weekStartDate);
      _initWeeklyMeals(); // تهيئة هيكل البيانات بناءً على الأسبوع المحدد
      _loadWeeklyPlan(); // تحميل خطة الأسبوع الموجودة
    } else {
      // إذا لم يتم تمرير تاريخ (حالة إنشاء خطة جديدة)
      final now = DateTime.now();
      // حساب تاريخ أول يوم في الأسبوع (الاثنين)
      // DateTime.now().weekday يعطي رقم اليوم (1 للإثنين، 7 للأحد)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      _weekStartDate = DateFormat('yyyy-MM-dd').format(monday);
      _currentWeekFirstDay = monday; // تعيين الاثنين كأول يوم في الأسبوع
      _initWeeklyMeals(); // تهيئة هيكل البيانات لأسبوع جديد فارغ
      // لا توجد خطة سابقة لتحميلها، لذا اجعل التحميل false
      setState(() {
        _isLoading = false;
      });
    }

    // تهيئة تواريخ حوار نسخ اليوم بناءً على الأسبوع الحالي
    _sourceDateForCopyDialog = _currentWeekFirstDay;
    // التاريخ المستهدف الافتراضي هو اليوم التالي، مع التحقق من عدم تجاوز الأسبوع
    DateTime potentialTargetDate = _currentWeekFirstDay.add(
      const Duration(days: 1),
    );
    final weekLastDay = _currentWeekFirstDay.add(
      const Duration(days: 6),
    ); // آخر يوم في الأسبوع هو بعد 6 أيام من اليوم الأول
    _targetDateForCopyDialog = potentialTargetDate.isAfter(weekLastDay)
        ? null // إذا تجاوز التاريخ الأسبوع، لا يوجد تاريخ مستهدف افتراضي
        : potentialTargetDate;
  }

  @override
  void dispose() {
    // التخلص من متحكم التبويب عند التخلص من الودجت
    _tabController.dispose();
    super.dispose();
  }

  // تهيئة هيكل البيانات _weeklyMeals
  void _initWeeklyMeals() {
    _weeklyMeals = {};
    final year = _currentWeekFirstDay.year;
    final month = _currentWeekFirstDay.month;
    final day = _currentWeekFirstDay.day;

    // إضافة 7 أيام للأسبوع
    for (int i = 0; i < 7; i++) {
      final date = DateTime(year, month, day).add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      // لكل يوم، تهيئة قائمة فارغة لكل نوع وجبة
      _weeklyMeals[dateStr] = {
        'breakfast': <Map<String, String>>[],
        'lunch': <Map<String, String>>[],
        'snack': <Map<String, String>>[],
        'dinner': <Map<String, String>>[],
      };
    }
  }

  // تحميل خطة الأسبوع من MealPlanService
  Future<void> _loadWeeklyPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // استدعاء خدمة MealPlanService لجلب خطة الأسبوع
      final weeklyPlan = await _mealPlanService.getWeeklyPlan(_weekStartDate);

      if (weeklyPlan.isNotEmpty) {
        setState(() {
          // تحويل البيانات المستلمة من الخدمة إلى الهيكل المطلوب
          _weeklyMeals = weeklyPlan.map((dateStr, mealTypes) {
            return MapEntry(
              dateStr,
              mealTypes.map((mealTypeKey, meals) {
                if (meals is List) {
                  // التأكد من أن الوجبات هي قائمة من الخرائط
                  return MapEntry(
                    mealTypeKey,
                    List<Map<String, String>>.from(
                      meals.map((m) => Map<String, String>.from(m as Map)),
                    ),
                  );
                }
                // fallback في حالة وجود نوع بيانات غير متوقع
                return MapEntry(mealTypeKey, <Map<String, String>>[]);
              }),
            );
          });
        });
      }
    } catch (e) {
      if (mounted) {
        // إظهار SnackBar في حالة وجود خطأ في التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المخطط الأسبوعي: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // حفظ خطة الأسبوع باستخدام MealPlanService
  Future<void> _saveWeeklyPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // استدعاء خدمة MealPlanService لحفظ خطة الأسبوع
      await _mealPlanService.saveWeeklyPlan(_weeklyMeals, _weekStartDate);

      if (mounted) {
        // إظهار SnackBar بنجاح الحفظ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الخطة الأسبوعية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        // إظهار SnackBar في حالة وجود خطأ في الحفظ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الخطة الأسبوعية: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // إضافة وجبة إلى اليوم المحدد ونوع الوجبة
  void _addMeal(String dateStr, String mealType) {
    final TextEditingController mealController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'إضافة وجبة لـ ${DateFormat('d MMMM', 'ar').format(DateTime.parse(dateStr))}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: mealController,
                      decoration: const InputDecoration(
                        hintText: 'اسم الوجبة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      keyboardType:
                          TextInputType.text, // يمكن أن تكون نصًا لـ "حبة"
                      decoration: const InputDecoration(
                        hintText: 'الكمية',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: unitController.text.isNotEmpty
                          ? unitController.text
                          : null,
                      items:
                          [
                                'كغ',
                                'غرام',
                                'مل',
                                'لتر',
                                'حبة',
                                'علبة',
                                'ملعقة',
                                'ملعقة صغيرة',
                                'ملعقة كبيرة',
                                'كوب',
                                'رشة',
                                'قطعة',
                                'شريحة',
                                'باكيت',
                                'صحن',
                                'حزمة',
                                'عبوة',
                                'ملفوفة',
                                'مقدار',
                                'جرام',
                                'مليلتر',
                                'أوقية',
                                'باوند',
                                'جرزة',
                                'حبة كبيرة',
                                'حبة صغيرة',
                                'كيس',
                                'حصة',
                              ]
                              .map(
                                (unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        unitController.text = value ?? '';
                      },
                      decoration: const InputDecoration(
                        labelText: 'الوحدة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        if (mealController.text.isNotEmpty) {
                          setState(() {
                            _weeklyMeals[dateStr]?[mealType]?.add({
                              'name': mealController.text.trim(),
                              'quantity': quantityController.text.trim(),
                              'unit': unitController.text.trim(),
                            });
                          });
                          Navigator.pop(
                            dialogContext,
                          ); // إغلاق مربع الحوار بعد الإضافة
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // صف لأزرار اختيار الوصفات
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('اختيار من وصفاتي'),
                      onPressed: () async {
                        Navigator.pop(
                          dialogContext,
                        ); // إغلاق مربع حوار الإضافة الحالي
                        final Recipe? selectedRecipe = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyRecipesScreen(
                              showAppBar: true,
                              onRecipeSelected: (Recipe recipe) {
                                Navigator.pop(
                                  context,
                                  recipe,
                                ); // إرجاع الوصفة المختارة
                              },
                              // توفير وظائف التفضيل والجدولة (من الكود الأول)
                              onToggleFavorite: (Recipe recipe) async {
                                return await RecipeService().toggleFavorite(
                                  recipe,
                                );
                              },
                              onScheduleRecipe: (BuildContext ctx, Recipe r) {},
                            ),
                          ),
                        );
                        if (selectedRecipe != null) {
                          // إذا تم اختيار وصفة، اطلب الكمية والوحدة لها
                          _showRecipeQuantityDialog(
                            dateStr,
                            mealType,
                            selectedRecipe,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر لإضافة وصفة جديدة
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('إضافة وصفة جديدة'),
                    onPressed: () async {
                      Navigator.pop(
                        dialogContext,
                      ); // إغلاق مربع حوار الإضافة الحالي
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRecipeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // زر لاختيار وصفة من الإنترنت (غير مفعل حاليًا)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.public),
                      label: const Text('اختيار وصفة من الانترنت'),
                      onPressed: null, // غير مفعل حالياً
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  // مربع حوار لطلب الكمية والوحدة لوصفة مختارة
  void _showRecipeQuantityDialog(
    String dateStr,
    String mealType,
    Recipe selectedRecipe,
  ) {
    final TextEditingController recipeQuantityController =
        TextEditingController();
    final TextEditingController recipeUnitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext2) {
        return AlertDialog(
          title: Text('كمية الوصفة: ${selectedRecipe.name}'),
          content: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: recipeQuantityController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'الكمية',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  // يمكن أن يكون DropdownFormField هنا كما في _addMeal
                  controller: recipeUnitController,
                  decoration: const InputDecoration(
                    hintText: 'الوحدة',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext2),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // إضافة الوجبة (الوصفة) إلى هيكل البيانات
                  _weeklyMeals[dateStr]?[mealType]?.add({
                    'name': selectedRecipe.name,
                    'quantity': recipeQuantityController.text.trim(),
                    'unit': recipeUnitController.text.trim(),
                  });
                });
                Navigator.pop(dialogContext2); // إغلاق مربع الحوار بعد الإضافة
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  // حذف وجبة من اليوم المحدد
  void _removeMeal(String dateStr, String mealType, int index) {
    setState(() {
      _weeklyMeals[dateStr]?[mealType]?.removeAt(index);
    });
  }

  // عرض واجهة المستخدم الرئيسية للشاشة
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تخطيط وجبات الأسبوع: ${_formatWeekRange()}',
        ), // عنوان يظهر نطاق الأسبوع
        actions: [
          IconButton(
            icon: const Icon(Icons.file_copy_outlined),
            onPressed: _showCopyDayOptions, // استدعاء دالة عرض خيارات نسخ اليوم
            tooltip: 'نسخ اليوم',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWeeklyPlan, // حفظ الخطة الأسبوعية
            tooltip: 'حفظ الخطة',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printMealPlan, // طباعة الخطة (غير مفعلة بالكامل)
            tooltip: 'طباعة الخطة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMealPlan, // مشاركة الخطة (غير مفعلة بالكامل)
            tooltip: 'مشاركة الخطة',
          ),
        ],
        // TabBar في الأسفل لعرض أيام الأسبوع
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // لجعل الألسنة قابلة للتمرير إذا كانت كثيرة
          tabs: _weekDays.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // عرض مؤشر التحميل
          : TabBarView(
              controller: _tabController,
              children: _weekDays.asMap().entries.map((entry) {
                // تمرير رقم اليوم (index) لبناء واجهة كل يوم
                int dayIndex = entry.key;
                return _buildDayMealPlan(dayIndex);
              }).toList(),
            ),
    );
  }

  // بناء واجهة تخطيط وجبات ليوم واحد
  Widget _buildDayMealPlan(int dayIndex) {
    // حساب التاريخ الفعلي لليوم في الأسبوع المحدد
    final date = _currentWeekFirstDay.add(Duration(days: dayIndex));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // ترجمة أسماء أنواع الوجبات للعرض
    final mealTypeNames = {
      'breakfast': 'الفطور',
      'lunch': 'الغداء',
      'snack': 'وجبة خفيفة',
      'dinner': 'العشاء',
    };

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          ) // مؤشر تحميل خاص باليوم (إذا كان هناك تحميل جزئي)
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // عرض التاريخ الفعلي لليوم
                Text(
                  DateFormat('d MMMM', 'ar').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      // بناء خانات الوجبات الأربعة (الإفطار، الغداء، الوجبة الخفيفة، العشاء)
                      _buildMealSlot(
                        dateStr,
                        'breakfast',
                        mealTypeNames['breakfast']!,
                      ),
                      _buildMealSlot(dateStr, 'lunch', mealTypeNames['lunch']!),
                      _buildMealSlot(dateStr, 'snack', mealTypeNames['snack']!),
                      _buildMealSlot(
                        dateStr,
                        'dinner',
                        mealTypeNames['dinner']!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  // بناء خانة وجبة واحدة (مثال: خانة الإفطار)
  Widget _buildMealSlot(
    String dateStr,
    String mealTypeKey,
    String mealDisplayName,
  ) {
    final mealsList = _weeklyMeals[dateStr]?[mealTypeKey] ?? [];

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        // عند النقر على البطاقة، افتح حوار إضافة وجبة
        onTap: () => _addMeal(dateStr, mealTypeKey),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان نوع الوجبة (مثال: الفطور)
              Text(
                mealDisplayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // إذا كانت قائمة الوجبات فارغة، اعرض رسالة "اضغط لإضافة وجبة"
              mealsList.isEmpty
                  ? const Text(
                      'اضغط لإضافة وجبة',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: mealsList.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> mealItem = entry.value;
                        String mealName = mealItem['name'] ?? 'وجبة غير مسماة';
                        String quantity = mealItem['quantity'] ?? '';
                        String unit = mealItem['unit'] ?? '';
                        String displayQuantity =
                            (quantity.isNotEmpty || unit.isNotEmpty)
                            ? ' ($quantity $unit)'.trim()
                            : '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('$mealName$displayQuantity'),
                              ),
                              // زر لحذف الوجبة
                              InkWell(
                                onTap: () =>
                                    _removeMeal(dateStr, mealTypeKey, index),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لعرض خيارات نسخ اليوم
  void _showCopyDayOptions() {
    // إعادة تعيين التواريخ الافتراضية عند فتح الحوار
    // يتم استخدام التاريخ الحالي في التاب المفتوح كقيمة افتراضية للمصدر
    final currentTabIndex = _tabController.index;
    _sourceDateForCopyDialog = _currentWeekFirstDay.add(
      Duration(days: currentTabIndex),
    );

    // التاريخ المستهدف الافتراضي هو اليوم التالي في نفس الأسبوع
    DateTime potentialTarget = _currentWeekFirstDay.add(
      Duration(days: currentTabIndex + 1),
    );
    final DateTime weekLastDay = _currentWeekFirstDay.add(
      const Duration(days: 6),
    );

    // إذا تجاوز التاريخ المستهدف نهاية الأسبوع، قم بتعيينه كأول يوم في الأسبوع (للتدوير)
    if (potentialTarget.isAfter(weekLastDay)) {
      _targetDateForCopyDialog = _currentWeekFirstDay;
    } else {
      _targetDateForCopyDialog = potentialTarget;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('نسخ وجبات اليوم'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'من اليوم:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _sourceDateForCopyDialog != null
                            ? DateFormat(
                                'EEE, d MMMM',
                                'ar',
                              ).format(_sourceDateForCopyDialog!)
                            : 'اختر تاريخ المصدر',
                      ),
                      ElevatedButton(
                        child: const Text('تغيير'),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _sourceDateForCopyDialog ??
                                _currentWeekFirstDay,
                            firstDate:
                                _currentWeekFirstDay, // لا يمكن اختيار تاريخ قبل بداية الأسبوع
                            lastDate: _currentWeekFirstDay.add(
                              const Duration(days: 6),
                            ), // لا يمكن اختيار تاريخ بعد نهاية الأسبوع
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _sourceDateForCopyDialog = picked;
                              // التأكد من أن التاريخين مختلفان تلقائيًا إذا تم تحديد نفس التاريخ
                              if (_sourceDateForCopyDialog ==
                                  _targetDateForCopyDialog) {
                                _targetDateForCopyDialog =
                                    _sourceDateForCopyDialog!.add(
                                      const Duration(days: 1),
                                    );
                                // إذا تجاوز التاريخ المستهدف نهاية الأسبوع بعد التغيير، قم بتعيينه كأول يوم في الأسبوع
                                if (_targetDateForCopyDialog!.isAfter(
                                  weekLastDay,
                                )) {
                                  _targetDateForCopyDialog =
                                      _currentWeekFirstDay;
                                }
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'إلى اليوم:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _targetDateForCopyDialog != null
                            ? DateFormat(
                                'EEE, d MMMM',
                                'ar',
                              ).format(_targetDateForCopyDialog!)
                            : 'اختر تاريخ الهدف',
                      ),
                      ElevatedButton(
                        child: const Text('تغيير'),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _targetDateForCopyDialog ??
                                _currentWeekFirstDay.add(
                                  const Duration(days: 1),
                                ),
                            firstDate: _currentWeekFirstDay,
                            lastDate: _currentWeekFirstDay.add(
                              const Duration(days: 6),
                            ),
                          );
                          if (picked != null &&
                              picked != _sourceDateForCopyDialog) {
                            setDialogState(() {
                              _targetDateForCopyDialog = picked;
                            });
                          } else if (picked != null &&
                              picked == _sourceDateForCopyDialog) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'لا يمكن نسخ اليوم إلى نفس اليوم المصدر.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_sourceDateForCopyDialog != null &&
                        _targetDateForCopyDialog != null) {
                      _copyDayMeals(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(_sourceDateForCopyDialog!),
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(_targetDateForCopyDialog!),
                      );
                      Navigator.pop(
                        dialogContext,
                      ); // إغلاق مربع الحوار بعد النسخ
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'الرجاء اختيار تاريخي المصدر والهدف.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('نسخ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // دالة لنسخ وجبات يوم واحد إلى يوم آخر
  void _copyDayMeals(String sourceDateStr, String targetDateStr) {
    setState(() {
      // التأكد من وجود اليوم المصدر قبل النسخ
      if (_weeklyMeals.containsKey(sourceDateStr)) {
        final sourceDayMeals = _weeklyMeals[sourceDateStr];
        // تهيئة اليوم الهدف إذا لم يكن موجودًا
        _weeklyMeals.putIfAbsent(targetDateStr, () => {});

        // نسخ الوجبات لكل نوع (إفطار، غداء، إلخ)
        final mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];
        for (final mealType in mealTypes) {
          if (sourceDayMeals!.containsKey(mealType) &&
              sourceDayMeals[mealType] != null) {
            // إنشاء قائمة جديدة لضمان عدم وجود مرجع مباشر
            _weeklyMeals[targetDateStr]![mealType] =
                List<Map<String, String>>.from(sourceDayMeals[mealType]!);
          } else {
            // إذا لم يكن هناك وجبات لنوع معين في المصدر، قم بمسحها في الهدف
            _weeklyMeals[targetDateStr]![mealType] = [];
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم نسخ الوجبات من $sourceDateStr إلى $targetDateStr',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'اليوم المصدر $sourceDateStr لا يحتوي على وجبات لنسخها.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // دالة مساعدة لتنسيق نطاق الأسبوع في عنوان AppBar
  String _formatWeekRange() {
    final start = DateFormat('yyyy-MM-dd').parse(_weekStartDate);
    final end = start.add(
      const Duration(days: 6),
    ); // نهاية الأسبوع بعد 6 أيام من البداية
    // تنسيق نطاق التاريخ (مثال: 01/07 - 07/07)
    return '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}';
  }

  // دوال لطباعة ومشاركة الخطة (احتياطية / غير مكتملة حاليا)
  Future<void> _printMealPlan() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              'خطة الوجبات الأسبوعية',
              textDirection: pw.TextDirection.rtl,
            ),
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/weekly_meal_plan.pdf');
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء ملف PDF لخطة الوجبات.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في إنشاء ملف PDF: $e')));
      }
    }
  }

  void _shareMealPlan() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وظيفة المشاركة قيد التنفيذ.')),
      );
    }
  }
}
