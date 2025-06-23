import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:monappmealplanning/app/domain/models/recipe_model.dart';
import 'package:monappmealplanning/app/data/services/recipe_service.dart';
import 'package:monappmealplanning/app/data/services/storage_service.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../domain/models/ingredient_model.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipeToEdit;

  const EditRecipeScreen({super.key, required this.recipeToEdit});

  // Optionnel: définir un nom de route pour la navigation
  // static const routeName = AppRoutes.editRecipe;

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

// Helper class for managing ingredient input controllers
class _IngredientFormController {
  final String id; // To keep track of existing ingredients for updates
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  _IngredientFormController({
    String? existingId,
    String? name,
    String? quantity,
    String? unit,
  }) : id = existingId ?? Uuid().v4(),
       nameController = TextEditingController(text: name ?? ''),
       quantityController = TextEditingController(text: quantity ?? ''),
       unitController = TextEditingController(text: unit ?? '');

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }

  Ingredient toIngredient() {
    return Ingredient(
      id: id,
      name: nameController.text.trim(),
      quantity: quantityController.text.trim(),
      unit: unitController.text.trim(),
      category: '', // Provide a default or appropriate value for category
    );
  }
}

class _EditRecipeScreenState extends State<EditRecipeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  final StorageService _storageService = StorageService();

  // Contrôleurs pour les champs de texte
  late TextEditingController _titleController;
  late TextEditingController _caloriesController;
  late TextEditingController _cookingTimeController;
  // late TextEditingController _costController; // Unused, _selectedCost is used
  // late TextEditingController _ingredientsController; // Replaced by _ingredientFormControllers
  late TextEditingController _instructionsController;
  late TextEditingController _descriptionController; // Added for description
  late TextEditingController _servingsController; // Added for servings

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _existingImageUrl;
  bool _isImageChanged = false;
  bool _isLoading = false;

  List<_IngredientFormController> _ingredientFormControllers = [];

  // تعريف متغير لتكلفة الوصفة
  String _selectedCost = 'متوسطة'; // القيمة الافتراضية

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.recipeToEdit.imageUrl;
    // تهيئة وحدة التحكم في علامات التبويب مع علامتي تبويب
    _tabController = TabController(length: 2, vsync: this);

    // ملء وحدات التحكم بالنص مع بيانات الوصفة الحالية
    _titleController = TextEditingController(text: widget.recipeToEdit.name);
    _descriptionController = TextEditingController(
      text: widget.recipeToEdit.description,
    );
    _caloriesController = TextEditingController(
      text: widget.recipeToEdit.calories?.toString() ?? '',
    );
    _cookingTimeController = TextEditingController(
      text: widget.recipeToEdit.cookingTime?.toString() ?? '',
    );
    _servingsController = TextEditingController(
      text: widget.recipeToEdit.servings?.toString() ?? '',
    );

    // تعيين تكلفة الوصفة من البيانات الموجودة
    if (widget.recipeToEdit.cost != null &&
        widget.recipeToEdit.cost!.isNotEmpty) {
      _selectedCost = widget.recipeToEdit.cost!;
    }

    // Initialize ingredient form controllers
    if (widget.recipeToEdit.ingredients.isNotEmpty) {
      _ingredientFormControllers = widget.recipeToEdit.ingredients
          .map(
            (ing) => _IngredientFormController(
              existingId: ing.id,
              name: ing.name,
              quantity: ing.quantity,
              unit: ing.unit,
            ),
          )
          .toList();
    } else {
      _addIngredientField(); // Add one empty field if no ingredients
    }
    // تحويل قائمة الخطوات إلى نص مع فواصل أسطر جديدة
    _instructionsController = TextEditingController(
      text: widget.recipeToEdit.steps
          .map((step) => step.description)
          .join('\n'),
    );
  }

  @override
  void dispose() {
    // Libère les ressources des contrôleurs
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _cookingTimeController.dispose();
    // _costController.dispose(); // Was unused
    // _ingredientsController.dispose(); // Replaced
    _instructionsController.dispose();
    _servingsController.dispose(); // Dispose servings controller
    for (var controller in _ingredientFormControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Méthode pour sélectionner une image depuis la galerie ou l'appareil photo
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isImageChanged = true;

          if (kIsWeb) {
            // For web platform
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _webImageBytes = bytes;
              });
            });
          } else {
            // For mobile platforms
            _imageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sélection d\'image: $e')),
        );
      }
    }
  }

  // طريقة لحفظ تغييرات الوصفة
  Future<void> _saveRecipeChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final String name = _titleController.text.trim();
      final String description = _descriptionController.text.trim();
      // final String ingredientsString = _ingredientsController.text.trim(); // Replaced
      final String instructionsString = _instructionsController.text.trim();

      final List<Ingredient> ingredientsList = _ingredientFormControllers
          .where(
            (controller) => controller.nameController.text.trim().isNotEmpty,
          )
          .map((controller) => controller.toIngredient())
          .toList();
      final List<String> instructionsList = instructionsString
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      // معالجة تحميل الصورة
      String? newImageUrl = widget.recipeToEdit.imageUrl;

      if (_isImageChanged) {
        try {
          if (kIsWeb && _webImageBytes != null) {
            // تحميل صورة الويب
            debugPrint("محاولة رفع صورة الويب...");
            final fileExtension =
                _imageFile != null && _imageFile!.path.isNotEmpty
                ? path.extension(_imageFile!.path)
                : '.jpg';
            newImageUrl = await _storageService.uploadRecipeImageBytes(
              _webImageBytes!,
              fileExtension,
            );
          } else if (!kIsWeb && _imageFile != null) {
            // تحميل صورة الجهاز المحمول
            debugPrint("محاولة رفع صورة الجهاز: ${_imageFile!.path}");
            newImageUrl = await _storageService.uploadRecipeImage(_imageFile!);
          }

          if (newImageUrl == null) {
            debugPrint("فشل في رفع الصورة");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'فشل في رفع الصورة. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
            // الاحتفاظ بعنوان URL الحالي إذا فشل التحميل
            newImageUrl = widget.recipeToEdit.imageUrl;
          } else {
            debugPrint("تم رفع الصورة بنجاح: $newImageUrl");
          }
        } catch (e) {
          debugPrint("خطأ أثناء رفع الصورة: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في رفع الصورة: $e'),
                duration: Duration(seconds: 5),
              ),
            );
          }
          // الاحتفاظ بعنوان URL الحالي إذا فشل التحميل
          newImageUrl = widget.recipeToEdit.imageUrl;
        }
      }

      final int? cookingTime = int.tryParse(_cookingTimeController.text.trim());
      final int? calories = int.tryParse(_caloriesController.text.trim());
      final int? servings = int.tryParse(_servingsController.text.trim());

      final updatedRecipe = Recipe(
        id: widget.recipeToEdit.id, // الاحتفاظ بالمعرف الأصلي
        userId: widget.recipeToEdit.userId, // Preserve original userId
        name: name,
        description: description,
        ingredients: ingredientsList, // Use the parsed ingredients
        steps: instructionsList
            .asMap()
            .entries
            .map(
              (entry) =>
                  RecipeStep(description: entry.value, order: entry.key + 1),
            )
            .toList(),
        imageUrl: newImageUrl,
        createdAt: widget.recipeToEdit.createdAt, // Preserve original createdAt
        cookingTime: cookingTime, // Pass int? directly
        preparationTime:
            widget.recipeToEdit.preparationTime, // Preserve prep time
        servings: servings, // Pass int? directly
        categories: widget.recipeToEdit.categories, // Preserve categories
        isFavorite: widget.recipeToEdit.isFavorite, // Preserve favorite status
        calories: calories, // Pass int? directly
        cost: _selectedCost, // استخدام التكلفة المحددة
      );

      try {
        await _recipeService.updateRecipe(updatedRecipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل الوصفة بنجاح!')),
          );
          Navigator.of(context).pop(updatedRecipe); // إرجاع الوصفة المحدثة
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في تعديل الوصفة: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint("نموذج غير صالح");
    }
  }

  void _addIngredientField() {
    setState(() {
      _ingredientFormControllers.add(_IngredientFormController());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      // Dispose controllers before removing
      _ingredientFormControllers[index].dispose();
      _ingredientFormControllers.removeAt(index);
      // Add an empty field if all are removed, to ensure there's always one input row
      if (_ingredientFormControllers.isEmpty) _addIngredientField();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الوصفة'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveRecipeChanges,
              tooltip: 'حفظ التغييرات',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // حقل اسم الوصفة
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم الوصفة',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال اسم الوصفة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // حقل الوصف
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الوصفة (اختياري)',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // قسم تحميل/تعديل الصورة
              Text(
                'صورة الوصفة',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return SafeArea(
                        child: Wrap(
                          children: <Widget>[
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('معرض الصور'),
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                                Navigator.of(context).pop();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('الكاميرا'),
                              onTap: () {
                                _pickImage(ImageSource.camera);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey.shade200,
                  ),
                  child: _buildImageWidget(),
                ),
              ),
              const SizedBox(height: 20),

              // حقول السعرات الحرارية، وقت الطهي
              _buildInfoRow(),
              const SizedBox(height: 16),
              _buildCostAndServingsRow(), // حقول التكلفة وعدد الحصص
              const SizedBox(height: 20),

              // علامات تبويب للمكونات والتحضير
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'المكونات'),
                  Tab(text: 'طريقة التحضير'),
                ],
              ),
              // محتوى علامات التبويب
              SizedBox(
                height: 300, // ارتفاع ثابت لعرض علامات التبويب
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIngredientsTab(),
                    _buildTextFieldForTab(
                      _instructionsController,
                      'خطوات التحضير (خطوة واحدة في كل سطر)...',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _ingredientFormControllers.length,
              itemBuilder: (context, index) {
                return _buildIngredientRow(index);
              },
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة مكون'),
            onPressed: _addIngredientField,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40), // Make button wider
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index) {
    final controller = _ingredientFormControllers[index];
    final List<String> units = [
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
      'ملعقة طعام',
      'ملعقة شاي',
      'ملعقة وسط',
      'ملعقة صغيرة جداً',
      'ملعقة كبيرة جداً',
      'ملعقة متوسطة',
      'ملع��ة صغيرة متوسطة',
      'ملعقة كبيرة متوسطة',
      'ملعقة صغيرة كبيرة',
      'ملعقة كبيرة صغيرة',
      'ملعقة صغيرة صغيرة',
      'ملعقة كبيرة كبيرة',
      'ملعقة صغيرة كبيرة جداً',
      'ملعقة كبيرة كبيرة جداً',
      'ملعقة صغيرة صغيرة جداً',
      'ملعقة كبيرة صغيرة جداً',
      'ملعقة صغيرة متوسطة جداً',
      'ملعقة كبيرة متوسطة جداً',
      'ملعقة صغيرة متوسطة جداً',
      'ملعقة كبيرة متوسطة جداً',
      'ملعقة صغيرة جداً جداً',
      'ملعقة كبيرة جداً جداً',
      'ملعقة صغيرة جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جد��ً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جدا�� جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة صغيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'ملعقة كبيرة جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً جداً',
      'أخرى...',
    ];
    String? selectedUnit = controller.unitController.text.isNotEmpty
        ? controller.unitController.text
        : null;
    bool isCustomUnit = selectedUnit != null && !units.contains(selectedUnit);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'المكون',
                border: OutlineInputBorder(),
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller.quantityController,
              decoration: const InputDecoration(
                labelText: 'الكمية',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  TextInputType.text, // Can be numbers or text like "1/2"
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: isCustomUnit ? null : (selectedUnit ?? units.first),
              items: [
                ...units.map(
                  (unit) => DropdownMenuItem(value: unit, child: Text(unit)),
                ),
              ],
              onChanged: (value) {
                controller.unitController.text = value ?? '';
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'الوحدة',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeIngredientField(index),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_isImageChanged) {
      if (kIsWeb && _webImageBytes != null) {
        // Web platform with selected image
        return ClipRRect(
          borderRadius: BorderRadius.circular(7.0),
          child: Image.memory(
            _webImageBytes!,
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
          ),
        );
      } else if (!kIsWeb && _imageFile != null) {
        // Mobile platform with selected image
        return ClipRRect(
          borderRadius: BorderRadius.circular(7.0),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
          ),
        );
      }
    }

    // Existing image from network or placeholder
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(7.0),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          height: 200,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text('Erreur de chargement de l\'image'),
            );
          },
        ),
      );
    } else {
      // Placeholder when no image is available
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(7.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 50,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'Appuyez pour ajouter une image',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }
  }

  // بناء صف المعلومات (السعرات الحرارية، الوقت)
  Widget _buildInfoRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: _caloriesController,
            decoration: const InputDecoration(
              labelText: 'السعرات الحرارية',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_fire_department_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'رقم غير صالح';
              }
              return null; // حقل اختياري
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _cookingTimeController,
            decoration: const InputDecoration(
              labelText: 'وقت الطهي (دقائق)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'رقم غير صالح';
              }
              return null; // حقل اختياري
            },
          ),
        ),
      ],
    );
  }

  // بناء صف التكلفة وعدد الحصص
  Widget _buildCostAndServingsRow() {
    return Row(
      children: <Widget>[
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCost,
            decoration: const InputDecoration(
              labelText: 'التكلفة',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'منخفضة', child: Text('منخفضة')),
              DropdownMenuItem(value: 'متوسطة', child: Text('متوسطة')),
              DropdownMenuItem(value: 'مرتفعة', child: Text('مرتفعة')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCost = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _servingsController,
            decoration: const InputDecoration(
              labelText: 'عدد الحصص',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.pie_chart_outline),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'رقم غير صالح';
              }
              return null; // حقل اختياري
            },
          ),
        ),
      ],
    );
  }

  // Widget pour les champs de texte dans les onglets - Identique à AddRecipeScreen
  Widget _buildTextFieldForTab(
    TextEditingController controller,
    String hintText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        textDirection: TextDirection.rtl,
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}
