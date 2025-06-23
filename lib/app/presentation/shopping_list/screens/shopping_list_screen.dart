import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/core/navigation/App_Routes.dart';
// import 'package:share_plus/share_plus.dart'; // Commented out
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:monappmealplanning/app/domain/models/shopping_list_model.dart';

// Temporary replacement for Share functionality
class ShareService {
  static void shareFiles(List<String> paths, {String? text}) {
    // Show a snackbar indicating sharing is temporarily disabled
    final messenger = GlobalKey<ScaffoldMessengerState>();
    messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Sharing is temporarily disabled. File saved at: ${paths.first}',
        ),
        duration: Duration(seconds: 5),
      ),
    );

    // Log the action
    print('Would share files: $paths with text: $text');
  }
}

// Modèle simple pour un élément de la liste de courses
class ShoppingListItem {
  String name;
  String quantity;
  String category;
  bool isChecked;

  ShoppingListItem({
    required this.name,
    this.quantity = '',
    required this.category,
    this.isChecked = false,
  });
}

class ShoppingListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  const ShoppingListScreen({Key? key, required this.items}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  final Map<String, List<ShoppingListItem>> _categorizedItems = {};

  @override
  Widget build(BuildContext context) {
    // Check if we're embedded in HomeScreen
    final bool isEmbedded =
        ModalRoute.of(context)?.settings.name != AppRoutes.shoppingList;

    return isEmbedded
        ? _buildContent()
        : Scaffold(
            appBar: AppBar(
              title: const Text('قائمة التسوق'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'طباعة القائمة',
                  onPressed: _printShoppingList,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'مشاركة القائمة',
                  onPressed: _shareShoppingList,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'إضافة منتج',
                  onPressed: _showAddItemDialog,
                ),
              ],
            ),
            body: _buildContent(),
          );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _categorizedItems.length,
            itemBuilder: (context, index) {
              final category = _categorizedItems.keys.elementAt(index);
              final items = _categorizedItems[category]!;

              return ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: items.map((item) {
                  return CheckboxListTile(
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(item.quantity ?? ''),
                    value: item.isChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        item.isChecked = value ?? false;
                      });
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          items.remove(item);
                          if (items.isEmpty) {
                            _categorizedItems.remove(category);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    String selectedCategory = _categorizedItems.keys.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إضافة منتج جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المنتج'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                  items: [
                    ..._categorizedItems.keys.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: 'new_category',
                      child: Text('إضافة فئة جديدة...'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'new_category') {
                      Navigator.of(context).pop();
                      _showNewCategoryDialog();
                    } else {
                      selectedCategory = value!;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('إضافة'),
              onPressed: () {
                final newItem = ShoppingListItem(
                  name: nameController.text,
                  quantity: quantityController.text,
                  category: selectedCategory,
                );
                setState(() {
                  if (!_categorizedItems.containsKey(selectedCategory)) {
                    _categorizedItems[selectedCategory] = [];
                  }
                  _categorizedItems[selectedCategory]!.add(newItem);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showNewCategoryDialog() {
    final TextEditingController newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إنشاء فئة جديدة'),
          content: TextField(
            controller: newCategoryController,
            decoration: const InputDecoration(labelText: 'اسم الفئة'),
          ),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('إنشاء'),
              onPressed: () {
                final newCategory = newCategoryController.text;
                if (newCategory.isNotEmpty &&
                    !_categorizedItems.containsKey(newCategory)) {
                  setState(() {
                    _categorizedItems[newCategory] = [];
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _printShoppingList() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'قائمة التسوق الخاصة بي',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ..._categorizedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;
                return pw.Column(
                  children: [
                    pw.Text(
                      category,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    ...items.map((item) {
                      return pw.Row(
                        children: [
                          pw.Checkbox(value: item.isChecked, name: ''),
                          pw.Text(item.name),
                          pw.Text(item.quantity),
                        ],
                      );
                    }),
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _shareShoppingList() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'قائمة التسوق الخاصة بي',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ..._categorizedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;
                return pw.Column(
                  children: [
                    pw.Text(
                      category,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    ...items.map((item) {
                      return pw.Row(
                        children: [
                          pw.Checkbox(value: item.isChecked, name: ''),
                          pw.Text(item.name),
                          pw.Text(item.quantity),
                        ],
                      );
                    }),
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/shopping_list.pdf');
    await file.writeAsBytes(await pdf.save());

    // Replace Share with our temporary ShareService
    // Share.shareFiles([file.path], text: 'قائمة التسوق الخاصة بي');

    // Show a dialog instead
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الملف في: ${file.path}'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  void printList() {
    _printShoppingList();
  }

  // Public method to share shopping list
  void shareShoppingList() {
    _shareShoppingList();
  }

  // Public method to show add item dialog
  void showAddItemDialog() {
    _showAddItemDialog();
  }

  // Public method to add items from external source (like meal plans)
  void addItemsFromShoppingList(List<ShoppingItem> shoppingItems) {
    setState(() {
      for (var shoppingItem in shoppingItems) {
        final category = shoppingItem.category.isEmpty ? 'عام' : shoppingItem.category;

        // Convert ShoppingItem to ShoppingListItem
        final item = ShoppingListItem(
          name: shoppingItem.name,
          quantity: '${shoppingItem.quantity} ${shoppingItem.unit}'.trim(),
          category: category,
          isChecked: false,
        );

        if (!_categorizedItems.containsKey(category)) {
          _categorizedItems[category] = [];
        }

        // Check if item already exists to avoid duplicates
        final existingItemIndex = _categorizedItems[category]!.indexWhere(
          (existingItem) => existingItem.name.toLowerCase() == item.name.toLowerCase(),
        );

        if (existingItemIndex != -1) {
          // Update existing item quantity
          final existingItem = _categorizedItems[category]![existingItemIndex];
          existingItem.quantity = '${existingItem.quantity} + ${item.quantity}';
        } else {
          // Add new item
          _categorizedItems[category]!.add(item);
        }
      }
    });
  }

  // Public method to clear all items
  void clearAllItems() {
    setState(() {
      _categorizedItems.clear();
    });
  }

  // Public method to get current items count
  int get itemsCount {
    return _categorizedItems.values.fold(0, (sum, items) => sum + items.length);
  }
}
