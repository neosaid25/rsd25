import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/core/theme/app_theme.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/presentation/favorites/screens/favorites_screen.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/my_plans_screen.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/schedule_recipe_screen.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/add_recipe_screen.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/my_recipes_screen.dart';
import 'package:monappmealplanning/app/presentation/shopping_list/screens/shopping_list_screen.dart';
import 'package:monappmealplanning/app/presentation/widgets/app_bottom_navigation_bar.dart';
import 'package:monappmealplanning/app/presentation/settings/screens/settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:monappmealplanning/app/data/services/meal_plan_service.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/weekly_meal_planning_screen.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/monthly_meal_planning_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Recipe> _recipes = []; // Liste principale des recettes
  final RecipeService _recipeService =
      RecipeService(); // Ajout du service de recettes

  // Clé globale pour accéder à l'état de ShoppingListScreen
  final GlobalKey<ShoppingListScreenState> _shoppingListScreenKey =
      GlobalKey<ShoppingListScreenState>();

  // Liste des widgets à afficher pour chaque onglet - sera initialisée dans initState ou build
  late List<Widget> _widgetOptions;

  // تعديل قائمة عناوين AppBar في HomeScreen
  static const List<String> _appBarTitles = <String>[
    'الشاشة الرئيسية',
    'قائمة التسوق',
    'وصفاتي',
    'خططي',
    'المفضلة',
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
    _initializeWidgetOptions();
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Builder(
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'مرحباً بك في تطبيق تخطيط وجباتي!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ابدأ بإضافة وصفاتك المفضلة وتخطيط وجباتك الأسبوعية والشهرية.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'خطط وجباتك',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildMenuItem(
                          context: context,
                          icon: Icons.calendar_today,
                          label: 'تخطيط الوجبات',
                          onTap: () => _showMealPlanningOptions(context),
                          color: AppTheme.primaryColor,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.menu_book_outlined,
                          label: 'وصفاتي',
                          onTap: () => _onItemTapped(2),
                          color: AppTheme.secondaryColor,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.shopping_cart_outlined,
                          label: 'قائمة التسوق',
                          onTap: () => _onItemTapped(1),
                          color: AppTheme.accentColor,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.event_note,
                          label: 'خططي',
                          onTap: () => _onItemTapped(3),
                          color: Colors.teal,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTodayMeals(),
                const SizedBox(height: 24),
                _buildWeeklyPlanPreview(),
              ],
            ),
          ),
        );
      },
    );
  }

  // عرض وجبات اليوم
  Widget _buildTodayMeals() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    return FutureBuilder<Map<String, Map<String, List<Map<String, String>>>>>(
      future: MealPlanService().getWeeklyPlan(
        DateFormat(
          'yyyy-MM-dd',
        ).format(now.subtract(Duration(days: now.weekday - 1))),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('حدث خطأ في تحميل وجبات اليوم');
        }

        final weeklyPlan = snapshot.data ?? {};
        final todayDayName = _getDayName(now.weekday);
        final todayMeals =
            weeklyPlan[todayDayName] ?? <String, List<Map<String, String>>>{};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'وجبات اليوم (${todayDayName})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToWeeklyPlanning(),
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealTypePreview(
                      'الفطور',
                      todayMeals['breakfast'] ?? [],
                    ),
                    const Divider(),
                    _buildMealTypePreview('الغداء', todayMeals['lunch'] ?? []),
                    const Divider(),
                    _buildMealTypePreview(
                      'وجبة خفيفة',
                      todayMeals['snack'] ?? [],
                    ),
                    const Divider(),
                    _buildMealTypePreview('العشاء', todayMeals['dinner'] ?? []),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // عرض نوع وجبة معين
  Widget _buildMealTypePreview(
    String mealTypeName,
    List<Map<String, String>> meals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mealTypeName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        meals.isEmpty
            ? const Text(
                'لا توجد وجبات مخططة',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: meals.map((mealItem) {
                  String mealName = mealItem['name'] ?? 'وجبة غير مسماة';
                  String quantity = mealItem['quantity'] ?? '';
                  String unit = mealItem['unit'] ?? '';
                  String displayQuantity =
                      (quantity.isNotEmpty || unit.isNotEmpty)
                      ? ' ($quantity $unit)'.trim()
                      : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('$mealName$displayQuantity'),
                  );
                }).toList(),
              ),
      ],
    );
  }

  // عرض معاينة للخطة الأسبوعية
  Widget _buildWeeklyPlanPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الخطة الأسبوعية',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _navigateToWeeklyPlanning(),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child:
              FutureBuilder<
                Map<String, Map<String, List<Map<String, String>>>>
              >(
                future: MealPlanService().getWeeklyPlan(
                  DateFormat('yyyy-MM-dd').format(
                    DateTime.now().subtract(
                      Duration(days: DateTime.now().weekday - 1),
                    ),
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Text('حدث خطأ في تحميل الخطة الأسبوعية');
                  }

                  final weeklyPlan = snapshot.data ?? {};
                  final daysOfWeek = [
                    'الإثنين',
                    'الثلاثاء',
                    'الأربعاء',
                    'الخميس',
                    'الجمعة',
                    'السبت',
                    'الأحد',
                  ];

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: daysOfWeek.length,
                    itemBuilder: (context, index) {
                      final day = daysOfWeek[index];
                      final dayMeals = weeklyPlan[day] ?? {};
                      int totalMeals = 0;
                      dayMeals.forEach((mealType, mealsList) {
                        totalMeals += (mealsList as List).length;
                      });

                      return Card(
                        margin: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _navigateToWeeklyPlanning(),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('$totalMeals وجبة'),
                                const SizedBox(height: 4),
                                if (totalMeals > 0)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  )
                                else
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  // الحصول على اسم اليوم بناءً على رقم اليوم في الأسبوع
  String _getDayName(int weekday) {
    final daysMap = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return daysMap[weekday] ?? '';
  }

  // الانتقال إلى شاشة التخطيط الأسبوعي
  void _navigateToWeeklyPlanning() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeeklyMealPlanningScreen()),
    );
  }

  // عرض خيارات تخطيط الوجبات
  void _showMealPlanningOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر نوع التخطيط',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('التخطيط الأسبوعي'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeeklyMealPlanningScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('التخطيط الشهري'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MonthlyMealPlanningScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _initializeWidgetOptions() {
    _loadRecipes(); // Charger les recettes au démarrage

    _widgetOptions = <Widget>[
      _buildHomeContent(context),
      // Use ShoppingListScreen without its AppBar
      Scaffold(
        body: ShoppingListScreen(key: _shoppingListScreenKey, items: const []),
        appBar: AppBar(
          title: Text(_appBarTitles[1]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onItemTapped(0), // العودة إلى الشاشة الرئيسية
          ),
          actions: _getAppBarActions(context),
        ),
      ),
      // Envelopper MyRecipesScreen dans un Scaffold avec un AppBar personnalisé
      Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[2]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onItemTapped(0), // العودة إلى الشاشة الرئيسية
          ),
          actions: _getAppBarActions(context),
        ),
        body: MyRecipesScreen(
          onRecipeSelected: (recipe) {
            // لا نفعل شيئًا هنا لأن التنقل يتم داخل MyRecipesScreen
          },
          onToggleFavorite: _toggleFavoriteStatus,
          onScheduleRecipe: (localContext, recipe) =>
              _navigateToScheduleRecipe(localContext, recipe),
          showAppBar: false, // Ne pas afficher l'AppBar de MyRecipesScreen
        ),
      ),
      Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[3]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onItemTapped(0), // العودة إلى الشاشة الرئيسية
          ),
        ),
        body: const MyPlansScreen(),
      ),
      Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[4]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onItemTapped(0), // العودة إلى الشاشة الرئيسية
          ),
        ),
        body: FavoritesScreen(
          favoriteRecipes: _recipes.where((r) => r.isFavorite).toList(),
          onToggleFavorite: _toggleFavoriteStatus,
          onScheduleRecipe: (localContext, recipe) =>
              _navigateToScheduleRecipe(localContext, recipe),
        ),
      ),
      Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitles[5]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onItemTapped(0), // العودة إلى الشاشة الرئيسية
          ),
        ),
        body: const SettingsScreen(),
      ),
    ];
  }

  Future<void> _loadRecipes() async {
    try {
      final recipes = await _recipeService.getUserRecipes();

      setState(() {
        _recipes.clear(); // Vider la liste actuelle
        _recipes.addAll(recipes); // Ajouter les nouvelles recettes
      });
    } catch (e) {
      print('Erreur lors du chargement des recettes: $e');
    }
  }

  Future<void> _navigateAndAddRecipe(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result != null && result is Recipe) {
      setState(() {
        _recipes.add(result);
        _initializeWidgetOptions(); // إعادة تهيئة الخيارات لتمرير القائمة المحدثة
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('تمت إضافة ${result.name} بنجاح!'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    }
  }

  Future<Recipe> _toggleFavoriteStatus(Recipe recipe) async {
    try {
      final updatedRecipe = await _recipeService.toggleFavorite(recipe);

      setState(() {
        final index = _recipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _recipes[index] = updatedRecipe;
        }

        // Réinitialiser les options de widget pour mettre à jour l'écran des favoris
        _initializeWidgetOptions();
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                updatedRecipe.isFavorite
                    ? 'تمت إضافة ${updatedRecipe.name} إلى المفضلة'
                    : 'تمت إزالة ${updatedRecipe.name} من المفضلة',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
      }

      return updatedRecipe;
    } catch (e) {
      print('Erreur lors de la mise à jour des favoris: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المفضلة: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return recipe; // Retourner la recette originale en cas d'erreur
    }
  }

  Future<void> _navigateToScheduleRecipe(
    BuildContext context,
    Recipe recipe,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleRecipeScreen(recipe: recipe),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      // يمكن إضافة منطق إضافي هنا للتعامل مع نتيجة برمجة الوصفة
      // مثل تحديث خطة الوجبات

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت برمجة ${recipe.name} بنجاح!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Il est important de réinitialiser _widgetOptions ici si, par exemple,
      // FavoritesScreen doit toujours refléter la liste _recipes la plus à jour
      // après une action qui pourrait la modifier (même si ce n'est pas directement
      // un changement d'onglet qui modifie _recipes).
      // Dans ce cas, comme _onItemTapped est appelé par les boutons du menu principal,
      // et que _initializeWidgetOptions reconstruit aussi le menu principal,
      // c'est cohérent.
      _initializeWidgetOptions();
    });
  }

  // Helper للحصول على إجراءات AppBar بناءً على الصفحة المحددة
  List<Widget>? _getAppBarActions(BuildContext context) {
    if (_selectedIndex == 1) {
      // مؤشر 'قائمة التسوق'
      return [
        IconButton(
          icon: const Icon(Icons.print),
          tooltip: 'طباعة القائمة',
          onPressed: () {
            if (_shoppingListScreenKey.currentState != null) {
              _shoppingListScreenKey.currentState!.printList();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'مشاركة القائمة',
          onPressed: () {
            if (_shoppingListScreenKey.currentState != null) {
              _shoppingListScreenKey.currentState!.shareShoppingList();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'إضافة منتج',
          onPressed: () {
            if (_shoppingListScreenKey.currentState != null) {
              _shoppingListScreenKey.currentState!.showAddItemDialog();
            }
          },
        ),
      ];
    } else if (_selectedIndex == 2) {
      // مؤشر 'وصفاتي'
      return [
        // زر تبديل عرض المفضلة فقط (si nous avons accès à l'état de MyRecipesScreen)
        // Pour l'instant, nous ajoutons seulement le bouton d'ajout de recette
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'إضافة وصفة جديدة',
          onPressed: () => _navigateAndAddRecipe(context),
        ),
      ];
    }
    // لا توجد إجراءات محددة للصفحات الأخرى حاليًا
    return null;
  }

  // إضافة زر للانتقال إلى صفحة "خططي"
  Widget _buildMyPlansButton() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyPlansScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.calendar_month, size: 48, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                'خططي المحفوظة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // نستخدم AppBar فقط للشاشة الرئيسية (index 0)
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Text(_appBarTitles[_selectedIndex]),
              centerTitle: true,
              actions: _getAppBarActions(context),
            )
          : null,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
