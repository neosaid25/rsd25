import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('الحساب'),
        _buildSettingItem(
          context,
          icon: Icons.person,
          title: 'الملف الشخصي',
          subtitle: 'تعديل معلومات الملف الشخصي',
          onTap: () {
            // التنقل إلى شاشة الملف الشخصي
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.lock,
          title: 'تغيير كلمة المرور',
          subtitle: 'تحديث كلمة المرور الخاصة بك',
          onTap: () {
            // التنقل إلى شاشة تغيير كلمة المرور
          },
        ),
        const Divider(),
        _buildSectionTitle('التطبيق'),
        _buildSettingItem(
          context,
          icon: Icons.notifications,
          title: 'الإشعارات',
          subtitle: 'إدارة إعدادات الإشعارات',
          onTap: () {
            // التنقل إلى شاشة الإشعارات
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.language,
          title: 'اللغة',
          subtitle: 'تغيير لغة التطبيق',
          onTap: () {
            // عرض خيارات اللغة
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.color_lens,
          title: 'المظهر',
          subtitle: 'تخصيص مظهر التطبيق',
          onTap: () {
            // عرض خيارات المظهر
          },
        ),
        const Divider(),
        _buildSectionTitle('عام'),
        _buildSettingItem(
          context,
          icon: Icons.help,
          title: 'المساعدة والدعم',
          subtitle: 'الأسئلة الشائعة والمساعدة',
          onTap: () {
            // التنقل إلى شاشة المساعدة
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.info,
          title: 'عن التطبيق',
          subtitle: 'معلومات عن الإصدار والتطوير',
          onTap: () {
            // عرض معلومات التطبيق
          },
        ),
        _buildSettingItem(
          context,
          icon: Icons.share,
          title: 'مشاركة التطبيق',
          subtitle: 'دعوة الأصدقاء لاستخدام التطبيق',
          onTap: () {
            // مشاركة التطبيق
          },
        ),
        const Divider(),
        _buildSettingItem(
          context,
          icon: Icons.exit_to_app,
          title: 'تسجيل الخروج',
          subtitle: 'الخروج من حسابك الحالي',
          onTap: () {
            // تسجيل الخروج
            _showLogoutConfirmationDialog(context);
          },
          showTrailingIcon: false,
        ),
        _buildSettingItem(
          context,
          icon: Icons.calendar_today,
          title: 'أول أيام الأسبوع',
          subtitle: 'تحديد اليوم الأول من الأسبوع',
          onTap: () {
            _showFirstDayOfWeekDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showTrailingIcon = true,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: showTrailingIcon
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // تنفيذ عملية تسجيل الخروج
              Navigator.pop(context);
              // ثم التنقل إلى شاشة تسجيل الدخول
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  void _showFirstDayOfWeekDialog(BuildContext context) {
    final List<String> weekDays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    String selectedDay = weekDays[0]; // افتراضي: الإثنين

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر أول أيام الأسبوع'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 300,
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: weekDays.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<String>(
                      title: Text(weekDays[index]),
                      value: weekDays[index],
                      groupValue: selectedDay,
                      onChanged: (value) {
                        setState(() {
                          selectedDay = value!;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                // هنا يمكنك حفظ اليوم المختار في الإعدادات
                _saveFirstDayOfWeek(selectedDay);
                Navigator.of(context).pop();

                // عرض رسالة تأكيد
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تعيين $selectedDay كأول أيام الأسبوع'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _saveFirstDayOfWeek(String day) {
    // هنا يمكنك حفظ اليوم في SharedPreferences أو في قاعدة البيانات
    // مثال باستخدام SharedPreferences:
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString('first_day_of_week', day);
    // });
  }
}
