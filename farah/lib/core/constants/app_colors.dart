import 'package:flutter/material.dart';

/// الهوية اللونية: وردي فاتح بنمط Claymorphism
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF48FB1);
  static const Color primaryDark = Color(0xFFE75480);
  static const Color primaryLight = Color(0xFFF8BBD0);

  static const Color background = Color(0xFFFDF2F7);
  static const Color softBackground = Color(0xFFFCE4EC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF5A2A3A);
  static const Color textSecondary = Color(0xFFA47585);

  static const Color gold = Color(0xFFC9A961);
  static const Color goldDark = Color(0xFF9B7B3F);
  static const Color goldLight = Color(0xFFE8D5A0);

  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);

  static const Color darkBackground = Color(0xFF2A1A22);
  static const Color darkSurface = Color(0xFF3A2630);
  static const Color darkTextPrimary = Color(0xFFF5E6EC);
  static const Color darkTextSecondary = Color(0xFFC9A8B5);

  // اسماء قديمة للتوافق مؤقتا
  static const Color goldPrimary = gold;
  static const Color pinkAccent = primaryLight;
  static const Color creamSurface = card;
  static const Color lightBackground = background;
  static const Color lightSurface = card;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
}
