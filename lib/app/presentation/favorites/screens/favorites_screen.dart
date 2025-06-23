import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/presentation/recipes/screens/recipe_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Recipe> favoriteRecipes;
  final Function(Recipe) onToggleFavorite;
  final Function(BuildContext, Recipe) onScheduleRecipe;

  const FavoritesScreen({
    super.key,
    required this.favoriteRecipes,
    required this.onToggleFavorite,
    required this.onScheduleRecipe,
  });

  // Constants for image and icon sizes, can be shared or defined locally
  static const double _kLeadingImageSize = 50.0;
  static const double _kLeadingIconSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: favoriteRecipes.isEmpty
          ? const Center(
              child: Text(
                'لا توجد وصفات مفضلة حاليًا.\nقم بإضافة وصفات إلى المفضلة لتظهر هنا.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: favoriteRecipes.length,
              itemBuilder: (context, index) {
                final recipe = favoriteRecipes[index];
                return ListTile(
                  leading: SizedBox(
                    width: _kLeadingImageSize,
                    height: _kLeadingImageSize,
                    child: recipe.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              4.0,
                            ), // Optional: for rounded corners
                            child: Image.network(
                              recipe.imageUrl!,
                              width: _kLeadingImageSize,
                              height: _kLeadingImageSize,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    size: _kLeadingIconSize,
                                  ),
                            ),
                          )
                        : const Icon(
                            Icons.restaurant_menu,
                            size: _kLeadingIconSize,
                          ),
                  ),
                  title: Text(recipe.name),
                  subtitle: Text(
                    // The null-aware operators provide a fallback.
                    'الوقت: ${recipe.cookingTime?.toString() ?? 'غير محدد'} دقيقة',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          true // Always show as favorite in favorites screen
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        tooltip: 'إزالة من المفضلة',
                        onPressed: () {
                          onToggleFavorite(recipe);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        tooltip: 'جدولة هذه الوصفة',
                        onPressed: () {
                          onScheduleRecipe(context, recipe);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to recipe details
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailsScreen(
                          recipe: recipe,
                          onToggleFavorite: onToggleFavorite,
                          onScheduleRecipe: onScheduleRecipe,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
