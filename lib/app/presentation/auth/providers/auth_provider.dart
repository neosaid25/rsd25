import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monappmealplanning/app/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // الحصول على المستخدم الحالي
  User? get user => _user;
  
  // التحقق مما إذا كان المستخدم مسجل الدخول
  bool get isLoggedIn => _user != null;
  
  // حالة التحميل
  bool get isLoading => _isLoading;
  
  // رسالة الخطأ
  String get errorMessage => _errorMessage;
  
  AuthProvider() {
    // تهيئة المزود بالمستخدم الحالي إن وجد
    _user = _authService.currentUser;
    
    // الاستماع لتغييرات حالة المصادقة
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }
  
  // معالجة تغييرات حالة المصادقة
  void _onAuthStateChanged(AuthState state) {
    _user = state.session?.user;
    notifyListeners();
  }
  
  // تعيين حالة التحميل
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // تعيين رسالة الخطأ
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  // مسح رسالة الخطأ
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    clearError();
    
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(_getMessageFromErrorCode(e.message));
      } else {
        _setError('حدث خطأ أثناء تسجيل الدخول');
      }
      _setLoading(false);
      return false;
    }
  }
  
  // إنشاء حساب جديد
  Future<bool> signUpWithEmailAndPassword(String email, String password, {String? fullName}) async {
    _setLoading(true);
    clearError();
    
    try {
      _user = await _authService.signUpWithEmailAndPassword(
        email, 
        password,
        fullName: fullName,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(_getMessageFromErrorCode(e.message));
      } else {
        _setError('حدث خطأ أثناء إنشاء الحساب');
      }
      _setLoading(false);
      return false;
    }
  }
  
  // تسجيل الدخول باستخدام Magic Link
  Future<bool> signInWithMagicLink(String email) async {
    _setLoading(true);
    clearError();
    
    try {
      await _authService.signInWithMagicLink(email);
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(_getMessageFromErrorCode(e.message));
      } else {
        _setError('حدث خطأ أثناء إرسال رابط تسجيل الدخول');
      }
      _setLoading(false);
      return false;
    }
  }
  
  // تسجيل الخروج
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _setError('حدث خطأ أثناء تسجيل الخروج');
    } finally {
      _setLoading(false);
    }
  }
  
  // إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    clearError();
    
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is AuthException) {
        _setError(_getMessageFromErrorCode(e.message));
      } else {
        _setError('حدث خطأ أثناء إرسال رابط إعادة تعيين كلمة المرور');
      }
      _setLoading(false);
      return false;
    }
  }
  
  // تحويل رموز الخطأ إلى رسائل مفهومة
  String _getMessageFromErrorCode(String code) {
    switch (code) {
      case 'invalid_credentials':
        return 'بيانات الاعتماد غير صالحة';
      case 'user_not_found':
        return 'لم يتم العثور على المستخدم';
      case 'invalid_email':
        return 'البريد الإلكتروني غير صالح';
      case 'email_taken':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak_password':
        return 'كلمة المرور ضعيفة جدًا';
      case 'too_many_requests':
        return 'عدد كبير جدًا من الطلبات، يرجى المحاولة لاحقًا';
      default:
        return 'حدث خطأ: $code';
    }
  }
}