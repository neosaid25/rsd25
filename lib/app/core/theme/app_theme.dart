import 'package:flutter/material.dart';

class AppTheme {
  // ألوان التطبيق الرئيسية
  static const Color primaryColor = Color(0xFF4CAF50); // أخضر
  static const Color secondaryColor = Color(0xFF8BC34A); // أخضر فاتح
  static const Color accentColor = Color(0xFFFFC107); // أصفر
  static const Color textColor = Color(0xFF212121); // أسود غامق
  static const Color backgroundColor = Color(0xFFF5F5F5); // رمادي فاتح

  // نمط السمة الفاتحة
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Tajawal', // خط عربي جميل - تأكد من إضافته في pubspec.yaml
      // نمط AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // نمط الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // نمط البطاقات
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // نمط النصوص
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: const TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: const TextStyle(color: textColor, fontSize: 16),
        bodyMedium: const TextStyle(color: textColor, fontSize: 14),
      ),
    );
  }

  // يمكنك إضافة نمط داكن هنا إذا أردت
  static ThemeData get darkTheme {
    // تعريف السمة الداكنة
    return ThemeData();
  }
}
