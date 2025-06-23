import 'package:flutter/material.dart';

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

  const RecipeListItem({
    super.key,
    required this.imageUrl,
    required this.recipeName,
    required this.calories,
    required this.cookingTime,
    required this.cost,
    required this.isFavorite,
    required this.onDelete,
    required this.onSchedule,
    required this.onFavorite,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الوصفة
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("خطأ في تحميل الصورة: $error");
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(
                Icons.image,
                size: 50,
                color: Colors.grey,
              ),
            ),
          
          // معلومات الوصفة
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان الوصفة
                Text(
                  recipeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // معلومات إضافية
                Row(
                  children: [
                    if (cookingTime.isNotEmpty)
                      Chip(
                        avatar: const Icon(
                          Icons.timer,
                          size: 16,
                        ),
                        label: Text('$cookingTime دقيقة'),
                        backgroundColor: Colors.blue[50],
                      ),
                    const SizedBox(width: 8),
                    if (calories.isNotEmpty)
                      Chip(
                        avatar: const Icon(
                          Icons.local_fire_department,
                          size: 16,
                        ),
                        label: Text('$calories سعرة'),
                        backgroundColor: Colors.orange[50],
                      ),
                    const SizedBox(width: 8),
                    if (cost.isNotEmpty)
                      Chip(
                        avatar: const Icon(
                          Icons.attach_money,
                          size: 16,
                        ),
                        label: Text(cost),
                        backgroundColor: Colors.green[50],
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // أزرار الإجراءات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                  onPressed: onFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  tooltip: 'جدولة الوصفة',
                  onPressed: onSchedule,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'تعديل الوصفة',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف الوصفة',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}