import 'package:flutter/material.dart';

/// الهوية اللونية الرسمية لتطبيق "فرح"
class AppColors {
  AppColors._();

  // الألوان الأساسية
  static const Color goldPrimary = Color(0xFFC9A961); // الذهبي الفاخر
  static const Color goldDark = Color(0xFF9B7B3F);
  static const Color goldLight = Color(0xFFE8D5A0);

  static const Color pinkAccent = Color(0xFFE8A0BF); // الوردي الراقي
  static const Color creamSurface = Color(0xFFFFFDF7); // الأبيض العاجي

  // ألوان الحالات
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // الوضع النهاري
  static const Color lightBackground = Color(0xFFFFFDF7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);

  // الوضع الليلي
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}
