import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/add_recipe_screen.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/edit_recipe_screen.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/recipe_details_screen.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/schedule_recipe_screen.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';

class MyRecipesScreen extends StatefulWidget {
  final bool showAppBar;
  final Function(Recipe)? onToggleFavorite;
  final Function(BuildContext, Recipe)? onScheduleRecipe;
  final Function(Recipe)? onRecipeSelected;

  const MyRecipesScreen({
    super.key,
    this.showAppBar = true,
    this.onToggleFavorite,
    this.onScheduleRecipe,
    this.onRecipeSelected,
  });

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // تحميل الوصفات من Supabase
  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await _recipeService.getUserRecipes();

      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل الوصفات: $e')));
      }
    }
  }

  // تصفية الوصفات بناءً على البحث والمفضلة
  List<Recipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      // فلترة بالبحث النصي
      final matchesSearchQuery =
          _searchQuery.isEmpty ||
          recipe.name.toLowerCase().contains(_searchQuery.toLowerCase());

      // فلترة بالمفضلة
      final matchesFavorite = !_showFavoritesOnly || recipe.isFavorite;

      return matchesSearchQuery && matchesFavorite;
    }).toList();
  }

  // حذف وصفة
  Future<void> _deleteRecipe(Recipe recipe) async {
    // عرض مربع حوار للتأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الوصفة؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
        // إضافة قيود واضحة للحوار
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 40.0,
          vertical: 24.0,
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await _recipeService.deleteRecipe(recipe.id);

      if (mounted) {
        setState(() {
          _recipes.removeWhere((r) => r.id == recipe.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الوصفة بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في حذف الوصفة: $e')));
      }
    }
  }

  // تبديل حالة المفضلة
  Future<void> _toggleFavorite(Recipe recipe) async {
    try {
      final updatedRecipe = await _recipeService.toggleFavorite(recipe);

      if (mounted) {
        setState(() {
          final index = _recipes.indexWhere((r) => r.id == recipe.id);
          if (index != -1) {
            _recipes[index] = updatedRecipe;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحديث المفضلة: $e')));
      }
    }
  }

  // الانتقال إلى شاشة تفاصيل الوصفة
  void _viewRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipe: recipe,
          onToggleFavorite: _toggleFavorite,
          onScheduleRecipe: (context, recipe) => _scheduleRecipe(recipe),
        ),
      ),
    );
  }

  // الانتقال إلى شاشة تعديل الوصفة
  Future<void> _editRecipe(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipeScreen(recipeToEdit: recipe),
      ),
    );

    if (result != null && result is Recipe) {
      setState(() {
        final index = _recipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _recipes[index] = result;
        }
      });
    }
  }

  // الانتقال إلى شاشة جدولة الوصفة
  void _scheduleRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleRecipeScreen(recipe: recipe),
      ),
    );
  }

  // إضافة وصفة جديدة
  Future<void> _addNewRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecipeScreen()),
    );

    if (result != null && result is Recipe) {
      setState(() {
        _recipes.add(result);
      });
    }
  }

  // Méthode pour gérer la sélection d'une recette
  void _handleRecipeSelection(Recipe recipe) {
    if (widget.onRecipeSelected != null) {
      // Si nous sommes en mode sélection, permettre à l'utilisateur de voir les détails avant de sélectionner
      _showRecipeDetailsDialog(recipe);
    } else {
      // Si nous ne sommes pas en mode sélection, naviguer vers les détails de la recette
      _viewRecipeDetails(recipe);
    }
  }

  // استبدال الحوار بالكامل بنسخة أبسط
  void _showRecipeDetailsDialog(Recipe recipe) {
    // استخدام حوار بسيط بدون عناصر معقدة
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (recipe.imageUrl.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'الوصف:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(recipe.description),
                  const SizedBox(height: 8),
                  Text('وقت التحضير: ${recipe.preparationTime} دقيقة'),
                  Text('وقت الطهي: ${recipe.cookingTime} دقيقة'),
                  Text('عدد الحصص: ${recipe.servings}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (widget.onRecipeSelected != null) {
                            widget.onRecipeSelected!(recipe);
                          }
                        },
                        child: const Text('اختيار هذه الوصفة'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {}, // Gestionnaire vide pour éviter les erreurs
      onExit: (_) {}, // Gestionnaire vide pour éviter les erreurs
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('وصفاتي'),
                actions: [
                  // زر تبديل عرض المفضلة فقط
                  IconButton(
                    icon: Icon(
                      _showFavoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _showFavoritesOnly ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFavoritesOnly = !_showFavoritesOnly;
                      });
                    },
                    tooltip: 'عرض المفضلة فقط',
                  ),
                  // زر التحديث
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadRecipes,
                    tooltip: 'تحديث',
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            // حقل البحث
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن وصفة...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // عرض الوصفات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRecipes.isEmpty
                  ? _buildEmptyState()
                  : _buildRecipesList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewRecipe,
          child: const Icon(Icons.add),
          tooltip: 'إضافة وصفة جديدة',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showFavoritesOnly ? Icons.favorite_border : Icons.restaurant,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showFavoritesOnly ? 'لا توجد وصفات مفضلة' : 'لا توجد وصفات',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _showFavoritesOnly
                ? 'أضف وصفات إلى المفضلة لتظهر هنا'
                : 'أضف وصفتك الأولى بالضغط على زر الإضافة',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (!_showFavoritesOnly)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: _addNewRecipe,
                icon: const Icon(Icons.add),
                label: const Text('إضافة وصفة جديدة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipesList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _filteredRecipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleRecipeSelection(recipe),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة الوصفة
            if (recipe.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // معلومات الوصفة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          recipe.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(recipe),
                        tooltip: recipe.isFavorite
                            ? 'إزالة من المفضلة'
                            : 'إضافة إلى المفضلة',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // أزرار الإجراءات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'تعديل',
                        onPressed: () => _editRecipe(recipe),
                      ),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'حذف',
                        onPressed: () => _deleteRecipe(recipe),
                      ),
                      _buildActionButton(
                        icon: Icons.calendar_today,
                        label: 'جدولة',
                        onPressed: () => _scheduleRecipe(recipe),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
