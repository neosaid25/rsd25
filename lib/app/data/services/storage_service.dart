import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:monappmealplanning/app/core/config/supabase_config.dart';

final _logger = Logger('StorageService');

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();

  // رفع صورة وصفة
  Future<String> uploadRecipeImage(File imageFile) async {
    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("يجب تسجيل الدخول لرفع الصور");
      }

      final String fileExtension = path.extension(imageFile.path);
      final String fileName = '${_uuid.v4()}$fileExtension';
      final String filePath = '${currentUser.id}/$fileName';

      // Convert dart:io File to Uint8List for Supabase Storage
      final Uint8List fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from(SupabaseConfig.recipeImagesStorage)
          .uploadBinary(filePath, fileBytes);

      // الحصول على رابط الصورة
      final String imageUrl = _supabase.storage
          .from(SupabaseConfig.recipeImagesStorage)
          .getPublicUrl(filePath);

      _logger.info('تم رفع صورة الوصفة بنجاح: $imageUrl');
      return imageUrl;
    } catch (e) {
      _logger.severe('خطأ في رفع صورة الوصفة: $e');
      throw Exception("فشل في رفع صورة الوصفة: $e");
    }
  }

  // رفع صورة المستخدم
  Future<String> uploadUserAvatar(File imageFile) async {
    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("يجب تسجيل الدخول لرفع الصور");
      }

      final String fileExtension = path.extension(imageFile.path);
      final String fileName = '${currentUser.id}$fileExtension';

      // Convert dart:io File to Uint8List for Supabase Storage
      final Uint8List fileBytes = await imageFile.readAsBytes();

      await _supabase.storage
          .from(SupabaseConfig.userAvatarsStorage)
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // الحصول على رابط الصورة
      final String imageUrl = _supabase.storage
          .from(SupabaseConfig.userAvatarsStorage)
          .getPublicUrl(fileName);

      _logger.info('تم رفع صورة المستخدم بنجاح: $imageUrl');
      return imageUrl;
    } catch (e) {
      _logger.severe('خطأ في رفع صورة المستخدم: $e');
      throw Exception("فشل في رفع صورة المستخدم: $e");
    }
  }

  // رفع صورة وصفة من بايتات (للويب وللموبايل)
  Future<String> uploadRecipeImageBytes(
    Uint8List imageBytes, [
    String? fileExtension,
  ]) async {
    try {
      final User? currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("يجب تسجيل الدخول لرفع الصور");
      }

      final String fileName = '${_uuid.v4()}${fileExtension ?? '.jpg'}';
      final String filePath = '${currentUser.id}/$fileName';

      await _supabase.storage
          .from(SupabaseConfig.recipeImagesStorage)
          .uploadBinary(filePath, imageBytes);

      // الحصول على رابط الصورة
      final String imageUrl = _supabase.storage
          .from(SupabaseConfig.recipeImagesStorage)
          .getPublicUrl(filePath);

      _logger.info('تم رفع صورة الوصفة بنجاح: $imageUrl');
      return imageUrl;
    } catch (e) {
      _logger.severe('خطأ في رفع صورة الوصفة: $e');
      throw Exception("فشل في رفع صورة الوصفة: $e");
    }
  }
}
