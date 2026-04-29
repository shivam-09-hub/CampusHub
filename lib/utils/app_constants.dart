import 'package:flutter/material.dart';

class AppColors {
  // Stitch "Kinetic Clarity" palette
  static const primary = Color(0xFF6750A4);
  static const secondary = Color(0xFF4ECDC4);
  static const surface = Color(0xFFF8F5FF);
  static const cardBg = Colors.white;

  // Subject color palette (soft pastel — matching Stitch)
  static const subjectColors = [
    Color(0xFFEDE7FF), // purple
    Color(0xFFFFECE0), // orange
    Color(0xFFE0FFF0), // green
    Color(0xFFFFF8E0), // gold
    Color(0xFFE0E8FF), // blue
    Color(0xFFE0FFF8), // teal
    Color(0xFFFFE0F0), // pink
    Color(0xFFE0F8FF), // cyan
  ];

  static const subjectAccents = [
    Color(0xFF6750A4),
    Color(0xFFFF6B4A),
    Color(0xFF2ECC71),
    Color(0xFFE7C365),
    Color(0xFF5B6CF7),
    Color(0xFF4ECDC4),
    Color(0xFFEF476F),
    Color(0xFF4AC8F7),
  ];
}

class AppConst {
  static const List<String> dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static String slotLabel(int index) => 'Slot ${index + 1}';
  static String dayLabel(int index) =>
      index < dayNames.length ? dayNames[index] : 'Day ${index + 1}';
}
