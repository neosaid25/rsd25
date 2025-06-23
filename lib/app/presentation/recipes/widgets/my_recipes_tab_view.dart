import 'package:flutter/material.dart';

class MyRecipesTabView extends StatelessWidget {
  const MyRecipesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Remplacer par de vraies données de recettes
    final recipes = List.generate(
      5,
      (index) => {
        'name': 'Nom de la recette ${index + 1}',
        'calories': '${200 + index * 50} kcal',
        'time': '${20 + index * 5} min',
        'cost': '€${3 + index}',
        // Assurez-vous d'avoir une image placeholder dans vos assets
        // ou remplacez par des URL d'images réelles.
        'imageUrl': 'assets/images/placeholder_recipe.png',
      },
    );

    return Column(
      children: [
        // Barre de recherche et de filtre
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une recette...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    // TODO: Implémenter la logique de recherche
                    print('Recherche: $value');
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filtrer les recettes',
                onPressed: () {
                  // TODO: Implémenter la logique de filtre (ex: afficher un dialogue ou un menu)
                  print('Bouton Filtre pressé');
                },
              ),
            ],
          ),
        ),
        // Liste des recettes
        Expanded(
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeListItem(
                imageUrl: recipe['imageUrl']!,
                recipeName: recipe['name']!,
                calories: recipe['calories']!,
                cookingTime: recipe['time']!,
                cost: recipe['cost']!,
                onDelete: () {
                  // TODO: Implémenter la suppression
                  print('Supprimer recette: ${recipe['name']}');
                },
                onSchedule: () {
                  // TODO: Implémenter la planification
                  print('Programmer recette: ${recipe['name']}');
                },
                onFavorite: () {
                  // TODO: Implémenter l'ajout aux favoris
                  print('Favoris recette: ${recipe['name']}');
                },
                onEdit: () {
                  // TODO: Implémenter la modification
                  print('Modifier recette: ${recipe['name']}');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecipeListItem extends StatelessWidget {
  final String imageUrl;
  final String recipeName;
  final String calories;
  final String cookingTime;
  final String cost;
  final bool isFavorite;
  final VoidCallback onDelete;
  final VoidCallback onSchedule;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final bool selectionMode; // إضافة وضع الاختيار

  const RecipeListItem({
    super.key,
    required this.imageUrl,
    required this.recipeName,
    required this.calories,
    required this.cookingTime,
    required this.cost,
    this.isFavorite = false,
    required this.onDelete,
    required this.onSchedule,
    required this.onFavorite,
    required this.onEdit,
    this.selectionMode = false, // افتراض غير مفعل
  });

  Widget _buildIconButton(
    IconData icon,
    VoidCallback onPressed,
    String tooltip, {
    Color? iconColor,
  }) {
    return IconButton(
      icon: Icon(icon, color: iconColor ?? Colors.white, size: 20.0),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
      splashRadius: 20.0,
    );
  }

  Widget _buildDetailItem(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.0,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4.0),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              // إذا كان في وضع الاختيار، أظهر أيقونة اختيار
              if (selectionMode)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                ),
              // إذا لم يكن في وضع الاختيار، أظهر أزرار التحكم العادية
              if (!selectionMode)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        _buildIconButton(
                          Icons.delete_outline,
                          onDelete,
                          'Supprimer',
                        ),
                        _buildIconButton(
                          Icons.calendar_today_outlined,
                          onSchedule,
                          'Programmer',
                        ),
                        _buildIconButton(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          onFavorite,
                          isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                          iconColor: isFavorite ? Colors.red : Colors.white,
                        ),
                        _buildIconButton(
                          Icons.edit_outlined,
                          onEdit,
                          'Modifier',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipeName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(
                      Icons.local_fire_department_outlined,
                      calories,
                      context,
                    ),
                    _buildDetailItem(
                      Icons.timer_outlined,
                      cookingTime,
                      context,
                    ),
                    _buildDetailItem(
                      Icons.attach_money_outlined,
                      cost,
                      context,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
