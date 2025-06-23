import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monappmealplanning/app/presentation/auth/screens/login_screen.dart';
import 'package:monappmealplanning/app/presentation/home/screens/home_screen.dart';
import 'package:monappmealplanning/app/presentation/common/widgets/loading_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // إذا كان هناك خطأ في الاتصال
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ في الاتصال',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // إعادة تحميل الصفحة
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                      );
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        // أثناء التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen(message: 'جاري التحميل...');
        }

        // إذا كان المستخدم مسجل الدخول
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const HomeScreen();
        }

        // إذا لم يكن المستخدم مسجل الدخول
        return LoginScreen();
      },
    );
  }
}
