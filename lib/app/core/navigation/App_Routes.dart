import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/login_screen.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/registration_screen.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/forgot_password.dart';
import 'package:monappmealplanning/app/presentation/home/screens/home_screen.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/auth_wrapper.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/welcome_screen.dart';
import 'package:monappmealplanning/app/presentation/shopping_list/screens/shopping_list_screen.dart';

class AppRoutes {
  // المسار الرئيسي هو شاشة الاستقبال
  static const String initialRoute = '/welcome';

  // Add the shopping list route
  static const String shoppingList = '/shopping-list';

  static final Map<String, WidgetBuilder> routes = {
    '/welcome': (context) => const WelcomeScreen(),
    '/auth': (context) => const AuthWrapper(),
    '/login': (context) => LoginScreen(),
    '/register': (context) => const RegistrationScreen(),
    '/forgot-password': (context) => ForgotPasswordScreen(),
    '/home': (context) => const HomeScreen(),
    '/shopping-list': (context) => const ShoppingListScreen(items: []),
  };
}
