import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/presentation/meal_planning/screens/schedule_recipe_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onToggleFavorite;
  final Function(BuildContext, Recipe) onScheduleRecipe;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
    required this.onToggleFavorite,
    required this.onScheduleRecipe,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  late Recipe _recipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  // دالة للانتقال إلى شاشة برمجة الوصفة
  Future<void> _navigateToScheduleRecipe(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleRecipeScreen(recipe: _recipe),
      ),
    );

    if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت برمجة ${_recipe.name} بنجاح!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // دالة لتبديل حالة المفضلة
  void _handleToggleFavorite(BuildContext context) async {
    // Stocker l'état actuel avant de le changer
    final bool currentState = _recipe.isFavorite;

    // Appeler la fonction pour changer l'état
    final updatedRecipe = await widget.onToggleFavorite(_recipe);

    // Mettre à jour l'état local si la fonction retourne une recette mise à jour
    if (updatedRecipe != null && mounted) {
      setState(() {
        _recipe = updatedRecipe;
      });
    }

    // عرض رسالة للمستخدم basée sur l'état AVANT le changement
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentState
                ? 'تمت إزالة ${_recipe.name} من المفضلة'
                : 'تمت إضافة ${_recipe.name} إلى المفضلة',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe.name),
        actions: [
          IconButton(
            icon: Icon(
              _recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _recipe.isFavorite ? Colors.red : null,
            ),
            onPressed: () => _handleToggleFavorite(context),
            tooltip: _recipe.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _navigateToScheduleRecipe(context),
            tooltip: 'جدولة الوصفة',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la recette
            if (_recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.network(
                  _recipe.imageUrl!,
                  fit: BoxFit.cover,
                  // إضافة فحص إضافي للتأكد من أن URL صالح
                  headers: const {'Accept': 'image/*'},
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            // Informations générales
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (_recipe.description != null &&
                      _recipe.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _recipe.description!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Informations (temps, calories, coût)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.timer,
                        '${_recipe.cookingTime ?? "N/A"} min',
                        Colors.blue,
                      ),
                      _buildInfoItem(
                        Icons.local_fire_department,
                        '${_recipe.calories ?? "N/A"} cal', // Affichage des calories
                        Colors.orange,
                      ),
                      _buildInfoItem(
                        Icons.attach_money,
                        _recipe.cost?.isNotEmpty == true
                            ? _recipe.cost!
                            : "N/A", // Affichage du coût
                        Colors.green,
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Ingrédients
                  const Text(
                    'Ingrédients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._recipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, size: 12),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Instructions
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value.description)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(text),
      ],
    );
  }
}
