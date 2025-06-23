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

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _IngredientFormController {
  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  _IngredientFormController({String? name, String? quantity, String? unit})
    : id = Uuid().v4(),
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

class _AddRecipeScreenState extends State<AddRecipeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  final StorageService _storageService = StorageService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _caloriesController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _instructionsController;
  late TextEditingController _servingsController;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Uint8List? _webImageBytes;
  bool _isImageChanged = false;
  bool _isLoading = false;

  List<_IngredientFormController> _ingredientFormControllers = [];

  String _selectedCost = 'متوسطة';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _caloriesController = TextEditingController();
    _cookingTimeController = TextEditingController();
    _servingsController = TextEditingController();
    _instructionsController = TextEditingController();
    _ingredientFormControllers = [];
    _addIngredientField();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _cookingTimeController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    for (var controller in _ingredientFormControllers) {
      controller.dispose();
    }
    super.dispose();
  }

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
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _webImageBytes = bytes;
              });
            });
          } else {
            _imageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في اختيار الصورة: $e')));
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      final String name = _titleController.text.trim();
      final String description = _descriptionController.text.trim();
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
      String? imageUrl;
      if (_isImageChanged) {
        try {
          if (kIsWeb && _webImageBytes != null) {
            final fileExtension =
                _imageFile != null && _imageFile!.path.isNotEmpty
                ? path.extension(_imageFile!.path)
                : '.jpg';
            imageUrl = await _storageService.uploadRecipeImageBytes(
              _webImageBytes!,
              fileExtension,
            );
          } else if (!kIsWeb && _imageFile != null) {
            imageUrl = await _storageService.uploadRecipeImage(_imageFile!);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('خطأ في رفع الصورة: $e')));
          }
        }
      }
      final int? cookingTime = int.tryParse(_cookingTimeController.text.trim());
      final int? calories = int.tryParse(_caloriesController.text.trim());
      final int? servings = int.tryParse(_servingsController.text.trim());
      final recipe = Recipe(
        id: '',
        userId: '',
        name: name,
        description: description,
        ingredients: ingredientsList,
        steps: instructionsList
            .asMap()
            .entries
            .map(
              (entry) =>
                  RecipeStep(description: entry.value, order: entry.key + 1),
            )
            .toList(),
        imageUrl: imageUrl ?? '',
        createdAt: DateTime.now(),
        cookingTime: cookingTime,
        preparationTime: 0,
        servings: servings,
        categories: [],
        isFavorite: false,
        calories: calories,
        cost: _selectedCost,
      );
      try {
        await _recipeService.addRecipe(recipe);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الوصفة بنجاح!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في إضافة الوصفة: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _addIngredientField() {
    setState(() {
      _ingredientFormControllers.add(_IngredientFormController());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredientFormControllers[index].dispose();
      _ingredientFormControllers.removeAt(index);
      if (_ingredientFormControllers.isEmpty) _addIngredientField();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة وصفة جديدة'),
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
              onPressed: _saveRecipe,
              tooltip: 'حفظ',
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
              _buildInfoRow(),
              const SizedBox(height: 16),
              _buildCostAndServingsRow(),
              const SizedBox(height: 20),
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
              SizedBox(
                height: 300,
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
              minimumSize: const Size(double.infinity, 40),
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
      'حزمة',
      'جرام',
      'كيس',
    ];
    String? selectedUnit = controller.unitController.text.isNotEmpty
        ? controller.unitController.text
        : null;
    bool isCustomUnit = selectedUnit != null && !units.contains(selectedUnit);
    TextEditingController customUnitController = TextEditingController(
      text: isCustomUnit ? selectedUnit : '',
    );

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
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: isCustomUnit ? null : (selectedUnit ?? units.first),
                  items: [
                    ...units.map(
                      (unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit)),
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
              ],
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
              'اضغط لإضافة صورة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

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
          ),
        ),
      ],
    );
  }

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
          ),
        ),
      ],
    );
  }

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
