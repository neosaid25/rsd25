import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:monappmealplanning/app/core/config/supabase_config.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger('AuthService');

  // الحصول على المستخدم الحالي
  User? get currentUser => _supabase.auth.currentUser;

  // التحقق مما إذا كان المستخدم مسجل الدخول
  bool get isLoggedIn => currentUser != null;

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _logger.info('تم تسجيل الدخول بنجاح: ${response.user?.email}');
      return response.user;
    } catch (e) {
      _logger.severe('خطأ في تسجيل الدخول: $e');
      rethrow;
    }
  }

  // إنشاء حساب جديد باستخدام البريد الإلكتروني وكلمة المرور
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? ''},
      );

      _logger.info('تم إنشاء حساب جديد بنجاح: ${response.user?.email}');
      return response.user;
    } catch (e) {
      _logger.severe('خطأ في إنشاء حساب جديد: $e');
      rethrow;
    }
  }

  // تسجيل الدخول باستخدام Magic Link
  Future<void> signInWithMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );

      _logger.info('تم إرسال رابط تسجيل الدخول إلى: $email');
    } catch (e) {
      _logger.severe('خطأ في إرسال رابط تسجيل الدخول: $e');
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _logger.info('تم تسجيل الخروج بنجاح');
    } catch (e) {
      _logger.severe('خطأ في تسجيل الخروج: $e');
      rethrow;
    }
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      _logger.info('تم إرسال رابط إعادة تعيين كلمة المرور إلى: $email');
    } catch (e) {
      _logger.severe('خطأ في إعادة تعيين كلمة المرور: $e');
      rethrow;
    }
  }

  // تحديث كلمة المرور
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _logger.info('تم تحديث كلمة المرور بنجاح');
    } catch (e) {
      _logger.severe('خطأ في تحديث كلمة المرور: $e');
      rethrow;
    }
  }

  // الاستماع لتغييرات حالة المصادقة
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
