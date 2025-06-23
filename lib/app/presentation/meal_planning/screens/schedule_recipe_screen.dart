import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';

class ScheduleRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const ScheduleRecipeScreen({super.key, required this.recipe});

  static const String routeName = '/schedule-recipe';

  @override
  State<ScheduleRecipeScreen> createState() => _ScheduleRecipeScreenState();
}

class _ScheduleRecipeScreenState extends State<ScheduleRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedWeek;
  String? _selectedDay;
  String? _selectedMealType;

  final List<String> _weeks = [
    'Semaine en cours',
    'Semaine 1',
    'Semaine 2',
    'Semaine 3',
    'Semaine 4',
  ];
  final List<String> _days = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  final List<String> _mealTypes = [
    'Petit-déjeuner',
    'Déjeuner',
    'Goûter',
    'Dîner',
  ];

  void _scheduleRecipe() {
    if (_formKey.currentState!.validate()) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Planification en cours..."),
                ],
              ),
            ),
          );
        },
      );

      // Simuler un délai pour l'enregistrement (à remplacer par votre logique réelle)
      Future.delayed(const Duration(milliseconds: 800), () {
        // Fermer le dialogue de chargement
        Navigator.pop(context);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.recipe.name} planifiée pour $_selectedDay, $_selectedMealType, $_selectedWeek.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () {
                // Naviguer vers la planification hebdomadaire ou mensuelle
                // selon le contexte
              },
            ),
          ),
        );

        // Retourner à l'écran précédent
        Navigator.pop(context, {
          'recipe': widget.recipe,
          'week': _selectedWeek,
          'day': _selectedDay,
          'mealType': _selectedMealType,
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Définir des valeurs par défaut
    _selectedWeek = _weeks[0]; // Semaine en cours
    _selectedDay = _days[DateTime.now().weekday - 1]; // Jour actuel
    _selectedMealType =
        _getMealTypeBasedOnTime(); // Type de repas selon l'heure
  }

  // Déterminer le type de repas en fonction de l'heure actuelle
  String _getMealTypeBasedOnTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return _mealTypes[0]; // Petit-déjeuner
    } else if (hour < 14) {
      return _mealTypes[1]; // Déjeuner
    } else if (hour < 18) {
      return _mealTypes[2]; // Goûter
    } else {
      return _mealTypes[3]; // Dîner
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planifier une recette'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Valider la planification',
            onPressed: _scheduleRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.recipe.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              // Display image from imageUrl with better UI
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child:
                    widget.recipe.imageUrl != null &&
                        widget.recipe.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              widget.recipe.imageUrl!,
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
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                              // إضافة فحص إضافي للتأكد من أن URL صالح
                              headers: const {'Accept': 'image/*'},
                            ),
                            // Overlay gradient for better text visibility if needed
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (widget.recipe.cookingTime != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.recipe.cookingTime} min',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    // Remove the calories display or replace with another property
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Aucune image disponible',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24.0),
              _buildDropdownFormField(
                label: 'Sélectionner la semaine',
                value: _selectedWeek,
                items: _weeks,
                onChanged: (value) => setState(() => _selectedWeek = value),
              ),
              const SizedBox(height: 16.0),
              _buildDropdownFormField(
                label: 'Sélectionner le jour',
                value: _selectedDay,
                items: _days,
                onChanged: (value) => setState(() => _selectedDay = value),
              ),
              const SizedBox(height: 16.0),
              _buildDropdownFormField(
                label: 'Sélectionner le type de repas',
                value: _selectedMealType,
                items: _mealTypes,
                onChanged: (value) => setState(() => _selectedMealType = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Veuillez sélectionner une option' : null,
    );
  }
}
