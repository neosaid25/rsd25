// lib/app/presentation/meal_planning/screens/monthly_meal_planning_screen.dart
import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/data/services/meal_plan_service.dart';
import 'package:intl/intl.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/my_recipes_screen.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../recipes/screens/add_recipe_screen.dart';

class MonthlyMealPlanningScreen extends StatefulWidget {
  final String? initialMonthStartDate;

  const MonthlyMealPlanningScreen({Key? key, this.initialMonthStartDate})
    : super(key: key);

  @override
  State<MonthlyMealPlanningScreen> createState() =>
      _MonthlyMealPlanningScreenState();
}

class _MonthlyMealPlanningScreenState extends State<MonthlyMealPlanningScreen>
    with TickerProviderStateMixin {
  final MealPlanService _mealPlanService = MealPlanService();

  // هيكل بيانات لتخزين وجبات الشهر
  late Map<String, Map<String, List<Map<String, String>>>> _monthlyMeals;

  bool _isLoading = true;
  String _monthStartDate = '';
  int _selectedWeek = 1;
  late DateTime _currentMonthFirstDay; // لتخزين تاريخ أول يوم في الشهر المحدد
  late TabController _tabController;
  final List<String> _weekDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  void initState() {
    super.initState();

    // تهيئة متحكم التبويب
    _tabController = TabController(length: _weekDays.length, vsync: this);

    // تهيئة تاريخ بداية الشهر
    // تهيئة هيكل البيانات أولاً لضمان وجوده دائمًا
    // سيتم تحديث _currentMonthFirstDay بناءً على ما إذا كان مخططًا جديدًا أم تعديلًا
    if (widget.initialMonthStartDate != null) {
      // حالة تعديل مخطط موجود
      _monthStartDate = widget.initialMonthStartDate!;
      _currentMonthFirstDay = DateFormat('yyyy-MM-dd').parse(_monthStartDate);
      _initMonthlyMeals(); // تهيئة بناءً على الشهر المحدد
      // تحميل المخطط الشهري الموجود
      _loadMonthlyPlan();
    } else {
      // حالة إنشاء مخطط جديد
      // الحصول على تاريخ بداية الشهر الحالي
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      _monthStartDate = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
      _currentMonthFirstDay = firstDayOfMonth;
      _initMonthlyMeals(); // تهيئة لشهر جديد فارغ
      // لا يتم تحميل مخطط سابق، _monthlyMeals مهيأ بالفعل وفارغ
      // اضبط isLoading على false لأننا لا نقوم بتحميل خطة
      setState(() {
        _isLoading = false;
      });
    }

    // تهيئة متغيرات حوار نسخ اليوم
    _sourceDateForCopyDialog = _currentMonthFirstDay;
    DateTime potentialTargetDate = _currentMonthFirstDay.add(
      const Duration(days: 1),
    );
    final monthLastDay = DateTime(
      _currentMonthFirstDay.year,
      _currentMonthFirstDay.month + 1,
      0,
    );
    _targetDateForCopyDialog = potentialTargetDate.isAfter(monthLastDay)
        ? null
        : potentialTargetDate;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initMonthlyMeals() {
    _monthlyMeals = {};
    final year = _currentMonthFirstDay.year;
    final month = _currentMonthFirstDay.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(year, month, i);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      _monthlyMeals[dateStr] = {
        'breakfast': <Map<String, String>>[],
        'lunch': <Map<String, String>>[],
        'snack': <Map<String, String>>[],
        'dinner': <Map<String, String>>[],
      };
    }
  }

  // تحميل المخطط الشهري من Firebase
  Future<void> _loadMonthlyPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final monthlyPlan = await _mealPlanService.getMonthlyPlan(
        _monthStartDate,
      );

      if (monthlyPlan.isNotEmpty) {
        setState(() {
          // Ensure correct type conversion from the service
          _monthlyMeals = monthlyPlan.map((dateStr, mealTypes) {
            return MapEntry(
              dateStr,
              mealTypes.map((mealTypeKey, meals) {
                if (meals is List) {
                  // Assuming meals are List<Map<String, String>> or can be cast
                  return MapEntry(
                    mealTypeKey,
                    List<Map<String, String>>.from(
                      meals.map((m) => Map<String, String>.from(m as Map)),
                    ),
                  );
                }
                // Fallback for safety
                return MapEntry(mealTypeKey, <Map<String, String>>[]);
              }),
            );
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المخطط الشهري: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // حفظ المخطط الشهري
  Future<void> _saveMonthlyPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _mealPlanService.saveMonthlyPlan(_monthlyMeals, _monthStartDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المخطط الشهري بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حفظ المخطط الشهري: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // إضافة وجبة إلى اليوم المحدد
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
                                'ملليلتر',
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
                            _monthlyMeals[dateStr]?[mealType]?.add({
                              'name': mealController.text.trim(),
                              'quantity': quantityController.text.trim(),
                              'unit': unitController.text.trim(),
                            });
                          });
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('اختيار من وصفاتي'),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        final Recipe? selectedRecipe = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyRecipesScreen(
                              showAppBar: true,
                              onRecipeSelected: (Recipe recipe) {
                                Navigator.pop(context, recipe);
                              },
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
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext2) {
                              final TextEditingController
                              recipeQuantityController =
                                  TextEditingController();
                              final TextEditingController recipeUnitController =
                                  TextEditingController();
                              return AlertDialog(
                                title: Text(
                                  'كمية الوصفة: ${selectedRecipe.name}',
                                ),
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
                                    onPressed: () =>
                                        Navigator.pop(dialogContext2),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _monthlyMeals[dateStr]?[mealType]?.add({
                                          'name': selectedRecipe.name,
                                          'quantity': recipeQuantityController
                                              .text
                                              .trim(),
                                          'unit': recipeUnitController.text
                                              .trim(),
                                        });
                                      });
                                      Navigator.pop(dialogContext2);
                                    },
                                    child: const Text('إضافة'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('إضافة وصفة جديدة'),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
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

  // حذف وجبة من اليوم المحدد
  void _removeMeal(String dateStr, String mealType, int index) {
    setState(() {
      _monthlyMeals[dateStr]?[mealType]?.removeAt(index);
    });
  }

  // إضافة زر حفظ في AppBar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تخطيط الوجبات الشهري'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed:
                _showCopyWeekOptions, // استدعاء دالة عرض خيارات نسخ الأسبوع
            tooltip: 'نسخ الأسبوع',
          ),
          IconButton(
            icon: const Icon(Icons.file_copy_outlined),
            onPressed: _showCopyDayOptions,
            tooltip: 'نسخ اليوم',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMonthlyPlan,
            tooltip: 'حفظ الخطة',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printMealPlan,
            tooltip: 'طباعة الخطة',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareMealPlan,
            tooltip: 'مشاركة الخطة',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<int>(
                    value: _selectedWeek,
                    items: List.generate(4, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('الأسبوع ${index + 1}'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedWeek = value;
                        });
                      }
                    },
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: _weekDays.map((day) => Tab(text: day)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _weekDays.asMap().entries.map((entry) {
                      int dayIndex = entry.key;
                      return _buildDayMealPlan(dayIndex);
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayMealPlan(int dayIndex) {
    // Calculate the date for this day in the selected week
    final dayOffset = (_selectedWeek - 1) * 7 + dayIndex;
    final date = _currentMonthFirstDay.add(Duration(days: dayOffset));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // التحقق إذا كان التاريخ المحسوب ضمن الشهر الحالي
    if (date.month != _currentMonthFirstDay.month) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Text(
          DateFormat('d MMMM', 'ar').format(date),
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  DateFormat('d MMMM', 'ar').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMealSlot(dateStr, 'breakfast'),
                      _buildMealSlot(dateStr, 'lunch'),
                      _buildMealSlot(dateStr, 'snack'),
                      _buildMealSlot(dateStr, 'dinner'),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildMealSlot(String dateStr, String mealType) {
    final mealsList = _monthlyMeals[dateStr]?[mealType] ?? [];

    // Translate meal type names
    final mealTypeNames = {
      'breakfast': 'الفطور',
      'lunch': 'الغداء',
      'snack': 'وجبة خفيفة',
      'dinner': 'العشاء',
    };

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _addMeal(dateStr, mealType),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealTypeNames[mealType] ?? mealType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                              InkWell(
                                onTap: () =>
                                    _removeMeal(dateStr, mealType, index),
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

  // عرض خيارات نسخ الأسبوع
  void _showCopyWeekOptions() {
    int sourceWeek = 1;
    int targetWeek = 2;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('نسخ وجبات الأسبوع'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'من الأسبوع',
                      border: OutlineInputBorder(),
                    ),
                    value: sourceWeek,
                    items: List.generate(4, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('الأسبوع ${index + 1}'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          sourceWeek = value;
                          // تأكد من أن الأسبوع المصدر والهدف مختلفان
                          if (sourceWeek == targetWeek) {
                            targetWeek = sourceWeek == 4 ? 3 : sourceWeek + 1;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'إلى الأسبوع',
                      border: OutlineInputBorder(),
                    ),
                    value: targetWeek,
                    items: List.generate(4, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('الأسبوع ${index + 1}'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null && value != sourceWeek) {
                        setState(() {
                          targetWeek = value;
                        });
                      }
                    },
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
                    _copyWeekMeals(sourceWeek - 1, targetWeek - 1);
                    Navigator.pop(dialogContext);
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

  void _copyWeekMeals(int sourceWeekIndex, int targetWeekIndex) {
    setState(() {
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        // حساب تاريخ اليوم المصدر
        final monthStart =
            _currentMonthFirstDay; // استخدام أول يوم في الشهر المحدد
        final sourceDayOffset = sourceWeekIndex * 7 + dayIndex;
        final sourceDate = monthStart.add(Duration(days: sourceDayOffset));
        final sourceDateStr = DateFormat('yyyy-MM-dd').format(sourceDate);

        // حساب تاريخ اليوم الهدف
        final targetDayOffset = targetWeekIndex * 7 + dayIndex;
        final targetDate = monthStart.add(Duration(days: targetDayOffset));
        final targetDateStr = DateFormat('yyyy-MM-dd').format(targetDate);

        // التأكد من أن التاريخين موجودان في الشهر الحالي
        final daysInMonth = DateTime(
          monthStart.year,
          monthStart.month + 1,
          0,
        ).day;
        if (sourceDate.month == monthStart.month &&
            targetDate.month == monthStart.month &&
            sourceDate.day <= daysInMonth &&
            targetDate.day <= daysInMonth) {
          // نسخ جميع أنواع الوجبات
          final mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];
          for (final mealType in mealTypes) {
            if (_monthlyMeals.containsKey(sourceDateStr) &&
                _monthlyMeals[sourceDateStr]?.containsKey(mealType) == true) {
              // إنشاء المفاتيح إذا لم تكن موجودة
              _monthlyMeals.putIfAbsent(targetDateStr, () => {});
              // Correctly copy the list of meal maps
              _monthlyMeals[targetDateStr]![mealType] =
                  List<Map<String, String>>.from(
                    _monthlyMeals[sourceDateStr]![mealType] ?? [],
                  );
            }
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الأسبوع ${sourceWeekIndex + 1} إلى الأسبوع ${targetWeekIndex + 1}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // متغيرات حالة لتخزين التواريخ المختارة في حوار نسخ اليوم
  DateTime? _sourceDateForCopyDialog;
  DateTime? _targetDateForCopyDialog;

  // عرض خيارات نسخ اليوم
  void _showCopyDayOptions() {
    // إعادة تعيين التواريخ الافتراضية عند فتح الحوار
    // يمكن تحسين هذه القيم الافتراضية لتكون أكثر ذكاءً بناءً على العرض الحالي
    _sourceDateForCopyDialog = _currentMonthFirstDay;
    DateTime potentialTarget = _currentMonthFirstDay.add(
      const Duration(days: 1),
    );
    final DateTime monthLastDay = DateTime(
      _currentMonthFirstDay.year,
      _currentMonthFirstDay.month + 1,
      0,
    );
    if (potentialTarget.isAfter(monthLastDay)) {
      _targetDateForCopyDialog = _currentMonthFirstDay;
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
                  Text(
                    'من اليوم:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _sourceDateForCopyDialog != null
                            ? DateFormat(
                                'EEE, d MMM yyyy',
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
                                _currentMonthFirstDay,
                            firstDate: _currentMonthFirstDay,
                            lastDate: monthLastDay,
                            locale: const Locale('ar'),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _sourceDateForCopyDialog = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'إلى اليوم:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _targetDateForCopyDialog != null
                            ? DateFormat(
                                'EEE, d MMM yyyy',
                                'ar',
                              ).format(_targetDateForCopyDialog!)
                            : 'اختر تاريخ الهدف',
                      ),
                      ElevatedButton(
                        child: const Text('تغيير'),
                        onPressed: () async {
                          DateTime initialPickerDate =
                              _targetDateForCopyDialog ??
                              _sourceDateForCopyDialog?.add(
                                const Duration(days: 1),
                              ) ??
                              _currentMonthFirstDay.add(
                                const Duration(days: 1),
                              );
                          if (initialPickerDate.isAfter(monthLastDay))
                            initialPickerDate = monthLastDay;
                          if (initialPickerDate.isBefore(_currentMonthFirstDay))
                            initialPickerDate = _currentMonthFirstDay;

                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initialPickerDate,
                            firstDate: _currentMonthFirstDay,
                            lastDate: monthLastDay,
                            locale: const Locale('ar'),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _targetDateForCopyDialog = picked;
                            });
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
                      if (_sourceDateForCopyDialog!.isAtSameMomentAs(
                        _targetDateForCopyDialog!,
                      )) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'لا يمكن النسخ إلى نفس اليوم. الرجاء اختيار تاريخ هدف مختلف.',
                            ),
                          ),
                        );
                        return;
                      }
                      _copyDayMeals(
                        _sourceDateForCopyDialog!,
                        _targetDateForCopyDialog!,
                      );
                      Navigator.pop(dialogContext);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء اختيار تاريخ المصدر والهدف.'),
                        ),
                      );
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

  // نسخ وجبات يوم محدد إلى يوم آخر
  void _copyDayMeals(DateTime sourceDate, DateTime targetDate) {
    final String sourceDateStr = DateFormat('yyyy-MM-dd').format(sourceDate);
    final String targetDateStr = DateFormat('yyyy-MM-dd').format(targetDate);

    if (!_monthlyMeals.containsKey(sourceDateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد بيانات لليوم المصدر: ${DateFormat('d MMM', 'ar').format(sourceDate)}',
          ),
        ),
      );
      return;
    }

    setState(() {
      _monthlyMeals[targetDateStr] ??= {
        'breakfast': <Map<String, String>>[],
        'lunch': <Map<String, String>>[],
        'snack': <Map<String, String>>[],
        'dinner': <Map<String, String>>[],
      };

      final mealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];
      for (final mealType in mealTypes) {
        final List<Map<String, String>> sourceMeals =
            List<Map<String, String>>.from(
              _monthlyMeals[sourceDateStr]?[mealType] ?? [],
            );
        _monthlyMeals[targetDateStr]![mealType] = sourceMeals;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ وجبات يوم ${DateFormat('d MMM', 'ar').format(sourceDate)} إلى يوم ${DateFormat('d MMM', 'ar').format(targetDate)}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Add this function to implement meal plan printing
  Future<void> _printMealPlan() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Create PDF document similar to shopping list printing
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'خطة الوجبات الشهرية',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                // Add week information
                pw.Text(
                  'الأسبوع $_selectedWeek',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Add meal plan content
                ...List.generate(7, (dayIndex) {
                  // Calculate the date for this day
                  final dayOffset = (_selectedWeek - 1) * 7 + dayIndex;
                  final date = _currentMonthFirstDay.add(
                    Duration(days: dayOffset),
                  );
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${_weekDays[dayIndex]} - ${DateFormat('d MMMM', 'ar').format(date)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      // Add meals for this day
                      ...['breakfast', 'lunch', 'snack', 'dinner'].map((
                        mealType,
                      ) {
                        final mealsList =
                            _monthlyMeals[dateStr]?[mealType] ?? [];
                        final mealTypeNames = {
                          'breakfast': 'الفطور',
                          'lunch': 'الغداء',
                          'snack': 'وجبة خفيفة',
                          'dinner': 'العشاء',
                        };

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${mealTypeNames[mealType]}:'),
                            ...mealsList.map((mealItem) {
                              String mealText = '  • ${mealItem['name']}';
                              if (mealItem['quantity']!.isNotEmpty ||
                                  mealItem['unit']!.isNotEmpty) {
                                mealText +=
                                    ' (${mealItem['quantity']} ${mealItem['unit']})';
                              }
                              return pw.Text(mealText);
                            }).toList(),
                            pw.SizedBox(height: 5),
                          ],
                        );
                      }),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      );

      // Save and open the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/meal_plan.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في طباعة المخطط الشهري: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Share meal plan functionality
  Future<void> _shareMealPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'خطة الوجبات الشهرية',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                // Add week information
                pw.Text(
                  'الأسبوع $_selectedWeek',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                // Add meal plan content for the selected week
                ...List.generate(7, (dayIndex) {
                  // Calculate the date for this day
                  final dayOffset = (_selectedWeek - 1) * 7 + dayIndex;
                  final date = _currentMonthFirstDay.add(
                    Duration(days: dayOffset),
                  );
                  final dateStr = DateFormat('yyyy-MM-dd').format(date);

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${_weekDays[dayIndex]} - ${DateFormat('d MMMM', 'ar').format(date)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      // Add meals for this day
                      ...['breakfast', 'lunch', 'snack', 'dinner'].map((
                        mealType,
                      ) {
                        final mealsList =
                            _monthlyMeals[dateStr]?[mealType] ?? [];
                        final mealTypeNames = {
                          'breakfast': 'الفطور',
                          'lunch': 'الغداء',
                          'snack': 'وجبة خفيفة',
                          'dinner': 'العشاء',
                        };

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${mealTypeNames[mealType]}:'),
                            ...mealsList.map((mealItem) {
                              String mealText = '  • ${mealItem['name']}';
                              if (mealItem['quantity']!.isNotEmpty ||
                                  mealItem['unit']!.isNotEmpty) {
                                mealText +=
                                    ' (${mealItem['quantity']} ${mealItem['unit']})';
                              }
                              return pw.Text(mealText);
                            }).toList(),
                            pw.SizedBox(height: 5),
                          ],
                        );
                      }),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/monthly_meal_plan.pdf');
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في مشاركة المخطط الشهري: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
