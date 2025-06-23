// lib/app/presentation/widgets/reusable_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:monappmealplanning/app/core/constants/app_constants.dart'; // Assurez-vous que le chemin est correct

class ReusableBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ReusableBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        for (var item in kBottomNavItems)
          BottomNavigationBarItem(icon: item.icon, label: item.label),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
    );
  }
}
