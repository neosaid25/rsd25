import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monappmealplanning/app/data/services/meal_plan_service.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/weekly_meal_planning_screen.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/monthly_meal_planning_screen.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';
import 'package:monappmealplanning/app/data/services/shopping_list_service.dart';
import 'package:monappmealplanning/app/presentation/shopping_list/screens/shopping_list_screen.dart';

class MyPlansScreen extends StatefulWidget {
  const MyPlansScreen({Key? key}) : super(key: key);

  @override
  State<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends State<MyPlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealPlanService _mealPlanService = MealPlanService();
  final RecipeService _recipeService = RecipeService();
  final ShoppingListService _shoppingListService = ShoppingListService();
  bool _isLoading = false;

  List<Map<String, dynamic>> _weeklyPlans = [];
  List<Map<String, dynamic>> _monthlyPlans = [];
  List<Recipe> _recipes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSavedPlans(), _loadRecipes()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSavedPlans() async {
    try {
      final [weeklyPlans, monthlyPlans] = await Future.wait([
        _mealPlanService.getSavedWeeklyPlans(),
        _mealPlanService.getSavedMonthlyPlans(),
      ]);

      setState(() {
        _weeklyPlans = weeklyPlans;
        _monthlyPlans = monthlyPlans;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل المخططات: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _recipeService.getUserRecipes();
      setState(() => _recipes = recipes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الوصفات: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // إنشاء قائمة تسوق من خطة أسبوعية
  Future<void> _generateShoppingListFromWeeklyPlan(String weekStartDate) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final shoppingItems = await _shoppingListService
          .generateShoppingListFromWeeklyPlan(weekStartDate);

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (shoppingItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مكونات في هذه الخطة لإنشاء قائمة تسوق'),
            ),
          );
        }
        return;
      }

      // إنشاء مفتاح للوصول إلى حالة قائمة التسوق
      final shoppingListKey = GlobalKey<ShoppingListScreenState>();

      // الانتقال إلى شاشة قائمة التسوق
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoppingListScreen(
              key: shoppingListKey,
              items: const [],
            ),
          ),
        );

        // إضافة العناصر بعد بناء الشاشة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          shoppingListKey.currentState?.addItemsFromShoppingList(shoppingItems);
        });

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء قائمة تسوق تحتوي على ${shoppingItems.length} عنصر'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء قائمة التسوق: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // إنشاء قائمة تسوق من خطة شهرية
  Future<void> _generateShoppingListFromMonthlyPlan(String monthStartDate) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final shoppingItems = await _shoppingListService
          .generateShoppingListFromMonthlyPlan(monthStartDate);

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (shoppingItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد مكونات في هذه الخطة لإنشاء قائمة تسوق'),
            ),
          );
        }
        return;
      }

      // إنشاء مفتاح للوصول إلى حالة قائمة التسوق
      final shoppingListKey = GlobalKey<ShoppingListScreenState>();

      // الانتقال إلى شاشة قائمة التسوق
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoppingListScreen(
              key: shoppingListKey,
              items: const [],
            ),
          ),
        );

        // إضافة العناصر بعد بناء الشاشة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          shoppingListKey.currentState?.addItemsFromShoppingList(shoppingItems);
        });

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء قائمة تسوق شهرية تحتوي على ${shoppingItems.length} عنصر'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء قائمة التسوق: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openWeeklyPlan(String weekStartDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WeeklyMealPlanningScreen(initialWeekStartDate: weekStartDate),
      ),
    ).then((_) => _loadSavedPlans());
  }

  void _openMonthlyPlan(String monthStartDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MonthlyMealPlanningScreen(initialMonthStartDate: monthStartDate),
      ),
    ).then((_) => _loadSavedPlans());
  }

  Widget _buildWeeklyPlansList() {
    if (_isLoading && _weeklyPlans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weeklyPlans.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مخططات أسبوعية محفوظة',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _weeklyPlans.length,
      itemBuilder: (context, index) {
        final plan = _weeklyPlans[index];
        final weekStartDate = plan['week_start_date'] as String;
        return _buildWeeklyPlanTable(weekStartDate);
      },
    );
  }

  Widget _buildWeeklyPlanTable(String weekStartDate) {
    final daysOfWeek = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final mealTypes = ['الفطور', 'الغداء', 'وجبة خفيفة', 'العشاء'];
    final mealTypeKeys = ['breakfast', 'lunch', 'snack', 'dinner'];

    return FutureBuilder<Map<String, Map<String, List<Map<String, String>>>>>(
      future: _mealPlanService.getWeeklyPlan(weekStartDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ في تحميل البيانات'));
        }

        final weeklyPlan = snapshot.data ?? {};
        final startDate = DateTime.parse(weekStartDate);
        final endDate = startDate.add(const Duration(days: 6));
        final formattedDate =
            '${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}';

        // إنشاء خريطة جديدة بربط أيام الأسبوع بالبيانات
        final Map<String, Map<String, List<Map<String, String>>>> weeklyData =
            {};

        for (int i = 0; i < 7; i++) {
          final currentDate = startDate.add(Duration(days: i));
          final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
          weeklyData[daysOfWeek[i]] = weeklyPlan[dateKey] ?? {};
        }

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'خطة الأسبوع: $formattedDate',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.green),
                          tooltip: 'إنشاء قائمة تسوق',
                          onPressed: () => _generateShoppingListFromWeeklyPlan(weekStartDate),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openWeeklyPlan(weekStartDate),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteWeeklyPlan(weekStartDate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: {
                    0: const FixedColumnWidth(100),
                    for (var i = 1; i <= daysOfWeek.length; i++)
                      i: const FixedColumnWidth(120),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.blue.shade50),
                      children: [
                        const SizedBox.shrink(),
                        ...daysOfWeek.map(
                          (day) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...mealTypes.asMap().entries.map((mealEntry) {
                      final mealIndex = mealEntry.key;
                      final mealName = mealEntry.value;

                      return TableRow(
                        children: [
                          Container(
                            color: Colors.blue.shade50,
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              mealName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ...daysOfWeek.map((day) {
                            final meals =
                                weeklyData[day]?[mealTypeKeys[mealIndex]] ?? [];

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: meals.isEmpty
                                  ? const Center(child: Text('-'))
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: meals
                                          .map(
                                            (meal) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4.0,
                                              ),
                                              child: Text('• ${meal['name']}'),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // باقي الدوال (المخططات الشهرية، الحذف، إلخ...) تبقى كما هي
  // ... (أضف هنا الدوال الأخرى مثل _buildMonthlyPlansList, _deleteWeeklyPlan, etc.)

  void _openWeeklyPlan(String weekStartDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeeklyMealPlanningScreen(),
      ),
    );
  }

  void _openMonthlyPlan(String monthStartDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonthlyMealPlanningScreen(),
      ),
    );
  }

  void _deleteWeeklyPlan(String weekStartDate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف خطة الأسبوع هذه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _mealPlanService.deleteWeeklyPlan(weekStartDate);
        await _loadSavedPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف خطة الأسبوع بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف خطة الأسبوع: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildMonthlyPlansList() {
    if (_isLoading && _monthlyPlans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthlyPlans.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد مخططات شهرية محفوظة',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _monthlyPlans.length,
      itemBuilder: (context, index) {
        final plan = _monthlyPlans[index];
        final monthStartDate = plan['month_start_date'] as String;
        return _buildMonthlyPlanCard(monthStartDate);
      },
    );
  }

  Widget _buildMonthlyPlanCard(String monthStartDate) {
    final startDate = DateTime.parse(monthStartDate);
    final endDate = DateTime(startDate.year, startDate.month + 1, 0);
    final formattedDate =
        '${DateFormat('yyyy/MM/dd').format(startDate)} - ${DateFormat('yyyy/MM/dd').format(endDate)}';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text(
          'خطة الشهر: $formattedDate',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.green),
              tooltip: 'إنشاء قائمة تسوق',
              onPressed: () => _generateShoppingListFromMonthlyPlan(monthStartDate),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _openMonthlyPlan(monthStartDate),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteMonthlyPlan(monthStartDate),
            ),
          ],
        ),
        onTap: () => _openMonthlyPlan(monthStartDate),
      ),
    );
  }

  void _deleteMonthlyPlan(String monthStartDate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف خطة الشهر هذه؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _mealPlanService.deleteMonthlyPlan(monthStartDate);
        await _loadSavedPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف خطة الشهر بنجاح')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف خطة الشهر: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خططي'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المخططات الأسبوعية'),
            Tab(text: 'المخططات الشهرية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeeklyPlansList(), _buildMonthlyPlansList()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMealPlanningOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMealPlanningOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('إضافة مخطط أسبوعي'),
              onTap: () {
                Navigator.pop(context);
                _openWeeklyPlan(
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('إضافة مخطط شهري'),
              onTap: () {
                Navigator.pop(context);
                _openMonthlyPlan(
                  DateFormat('yyyy-MM-01').format(DateTime.now()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
