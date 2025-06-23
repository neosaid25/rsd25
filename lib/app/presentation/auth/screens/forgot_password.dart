import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monappmealplanning/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String email = _emailController.text.trim();

      try {
        bool success = await authProvider.sendPasswordResetEmail(email);

        if (mounted) {
          if (success) {
            setState(() {
              _emailSent = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // عرض رسالة الخطأ من AuthProvider
            if (authProvider.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _emailSent ? _buildSuccessView() : _buildRequestForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // أيقونة القفل
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 24),

          // عنوان الشاشة
          Text(
            'نسيت كلمة المرور؟',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // وصف العملية
          Text(
            'أدخل بريدك الإلكتروني أدناه وسنرسل لك رابطًا لإعادة تعيين كلمة المرور الخاصة بك.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // حقل البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'example@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال بريدك الإلكتروني';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'الرجاء إدخال بريد إلكتروني صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // زر إرسال رابط إعادة التعيين
          ElevatedButton(
            onPressed: _isLoading ? null : _sendResetLink,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'إرسال رابط إعادة التعيين',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),

          // زر العودة إلى تسجيل الدخول
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'العودة إلى تسجيل الدخول',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // معلومات إضافية
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ملاحظة مهمة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'إذا لم تجد رسالة إعادة تعيين كلمة المرور في صندوق الوارد، يرجى التحقق من مجلد البريد العشوائي (Spam) أو مجلد البريد غير المرغوب فيه (Junk).',
                  style: TextStyle(color: Colors.blue.shade700, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // أيقونة النجاح
        Icon(
          Icons.check_circle_outline,
          size: 100,
          color: Colors.green.shade600,
        ),
        const SizedBox(height: 24),

        // عنوان النجاح
        Text(
          'تم إرسال رابط إعادة التعيين!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 16),

        // وصف الخطوات التالية
        Text(
          'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),

        // تعليمات إضافية
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الخطوات التالية:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildStep(
                1,
                'افتح بريدك الإلكتروني واضغط على الرابط المرسل إليك.',
                Icons.email_outlined,
              ),
              const SizedBox(height: 8),
              _buildStep(
                2,
                'أدخل كلمة مرور جديدة في الصفحة التي ستظهر لك.',
                Icons.lock_outline,
              ),
              const SizedBox(height: 8),
              _buildStep(
                3,
                'سجل دخولك باستخدام كلمة المرور الجديدة.',
                Icons.login_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // زر العودة إلى تسجيل الدخول
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'العودة إلى تسجيل الدخول',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),

        // زر إعادة إرسال الرابط
        TextButton(
          onPressed: _isLoading ? null : _sendResetLink,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'إعادة إرسال الرابط',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(height: 1.5, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
