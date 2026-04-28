import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4A6CF7);
  static const secondary = Color(0xFF6C63FF);
  static const surface = Color(0xFFF8F9FF);
  static const cardBg = Colors.white;

  // Subject color palette (soft pastel)
  static const subjectColors = [
    Color(0xFFE3EAFF), // blue
    Color(0xFFFFE8E3), // orange
    Color(0xFFE3FFE8), // green
    Color(0xFFFFF3E3), // yellow
    Color(0xFFF3E3FF), // purple
    Color(0xFFE3FFF8), // teal
    Color(0xFFFFE3F3), // pink
    Color(0xFFE3F8FF), // cyan
  ];

  static const subjectAccents = [
    Color(0xFF4A6CF7),
    Color(0xFFFF6B4A),
    Color(0xFF4AE36B),
    Color(0xFFFFB84A),
    Color(0xFFB84AF7),
    Color(0xFF4AF7D6),
    Color(0xFFF74AA8),
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
