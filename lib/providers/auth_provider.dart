import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(AuthState state) {
    try {
      _user = state.session?.user;
      if (_user == null) {
        print("Utilisateur déconnecté");
      } else {
        print("Utilisateur connecté: ${_user!.email}");
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      print("Error in auth state change: $e");
    }
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider SignIn Error: $e');
      if (e is AuthException) {
        if (e.message == 'Invalid email or password') {
          _setError(
            'Identifiants incorrects. Veuillez vérifier votre e-mail et mot de passe.',
          );
        } else if (e.message == 'Email not confirmed') {
          _setError('L\'adresse e-mail n\'est pas confirmée.');
        } else {
          _setError('Une erreur est survenue lors de la connexion.');
        }
      } else {
        _setError('Une erreur inattendue est survenue.');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      await _supabase.auth.signUp(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider SignUp Error: $e');
      if (e is AuthException) {
        if (e.message == 'Password strength is too low') {
          _setError('Le mot de passe fourni est trop faible.');
        } else if (e.message == 'Email already in use') {
          _setError('Un compte existe déjà pour cet e-mail.');
        } else if (e.message == 'Invalid email address') {
          _setError('L\'adresse e-mail n\'est pas valide.');
        } else {
          _setError('Une erreur est survenue lors de l\'inscription.');
        }
      } else {
        _setError('Une erreur inattendue est survenue.');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true); // Optionnel, la déconnexion est généralement rapide
    await _supabase.auth.signOut();
    _setLoading(false);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider Password Reset Error: $e');
      if (e is AuthException) {
        if (e.message == 'User not found') {
          _setError(
            'Aucun utilisateur trouvé pour cet e-mail ou l\'e-mail est invalide.',
          );
        } else {
          _setError(
            'Erreur lors de l\'envoi de l\'e-mail de réinitialisation.',
          );
        }
      } else {
        _setError('Une erreur inattendue est survenue.');
      }
      _setLoading(false);
      return false;
    }
  }

  // إضافة طريقة تسجيل الدخول باستخدام Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      // بدء عملية تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // المستخدم ألغى عملية تسجيل الدخول
        _setLoading(false);
        return false;
      }

      // الحصول على بيانات المصادقة من طلب Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create OAuth credentials for Supabase
      final provider = Provider.google;
      // Remove the unused params variable

      // تسجيل الدخول باستخدام بيانات الاعتماد
      await _supabase.auth.signInWithOAuth(
        provider,
        queryParams: {
          'access_token': googleAuth.accessToken ?? '',
          'id_token': googleAuth.idToken ?? '',
        },
      );
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider Google SignIn Error: $e');
      _setError('حدث خطأ أثناء تسجيل الدخول باستخدام Google');
      _setLoading(false);
      return false;
    }
  }

  // إضافة طريقة تسجيل الدخول باستخدام Facebook
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _clearError();
    try {
      // بدء عملية تسجيل الدخول بـ Facebook
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status != LoginStatus.success) {
        // فشل تسجيل الدخول أو تم إلغاؤه
        _setError('فشل تسجيل الدخول باستخدام Facebook');
        _setLoading(false);
        return false;
      }

      // تسجيل الدخول باستخدام Supabase OAuth
      final provider = Provider.facebook;
      await _supabase.auth.signInWithOAuth(
        provider,
        queryParams: {'access_token': result.accessToken?.token ?? ''},
      );
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider Facebook SignIn Error: $e');
      _setError('حدث خطأ أثناء تسجيل الدخول باستخدام Facebook');
      _setLoading(false);
      return false;
    }
  }
}
