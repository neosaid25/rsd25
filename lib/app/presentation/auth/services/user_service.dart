import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';

final _logger = Logger('UserService');

class UserService {
  final _supabase = Supabase.instance.client;

  Future<void> saveUserData(User user, {String? displayName}) async {
    try {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': displayName ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.severe("خطأ في حفظ بيانات المستخدم ${user.id}: $e");
      // Consider re-throwing to inform the caller about the failure
      // throw Exception("فشل في حفظ بيانات المستخدم ${user.id}. خطأ: $e");
    }
  }
}
