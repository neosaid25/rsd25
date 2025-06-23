// lib/app/core/constants/app_constants.dart
import 'package:flutter/material.dart';

// Days of the week
const List<String> kDaysOfWeek = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

// Meal types
const List<String> kMealTypes = [
  'Petit-déjeuner',
  'Déjeuner',
  'Collation',
  'Dîner',
];

// Bottom Navigation Bar Items
const List<NavigationDestination> kBottomNavItems = [
  NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
  NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Plans'),
  NavigationDestination(icon: Icon(Icons.list_alt), label: 'Courses'),
  NavigationDestination(icon: Icon(Icons.settings), label: 'Paramètres'),
];

// Padding and Spacing (Exemples)
const double kDefaultPadding = 16.0;
const double kDefaultSpace = 20.0;

// Colors (Exemples - vous pouvez les définir dans votre thème aussi)
// const Color kPrimaryColor = Colors.blue;
// const Color kSecondaryColor = Colors.grey;
