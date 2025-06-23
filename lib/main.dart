import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monappmealplanning/app/core/navigation/App_Routes.dart';
import 'package:monappmealplanning/app/core/config/supabase_config.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:monappmealplanning/app/presentation/auth/providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة بيانات التنسيق للغة العربية
  await initializeDateFormatting('ar', null);

  // تهيئة نظام التسجيل
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // تهيئة Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // أضف المزيد من موفري الحالة هنا
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق برمجة الوجبات',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Cairo', // تأكد من إضافة الخط العربي في pubspec.yaml
        textTheme: TextTheme(
          // تخصيص أنماط النصوص للدعم العربي
          bodyLarge: TextStyle(height: 1.5),
          bodyMedium: TextStyle(height: 1.5),
        ),
      ),
      // إضافة دعم اللغة العربية
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ar', 'SA'), // العربية السعودية
        Locale('en', 'US'), // الإنجليزية الأمريكية
      ],
      locale: Locale('ar', 'SA'), // تعيين اللغة الافتراضية للعربية
      debugShowCheckedModeBanner: false,
      initialRoute:
          AppRoutes.initialRoute, // استخدام المسار الأولي من AppRoutes
      routes: AppRoutes.routes,
    );
  }
}
