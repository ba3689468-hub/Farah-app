import 'package:flutter/material.dart';

// لوحة الألوان: وردي غني وحيوي، تدرجات باستيل، Claymorphism
class AppColors {
  AppColors._();

  // ✅ تم تعديل الألوان الأساسية لتكون أكثر عمقاً وحيوية
  static const Color primary = Color(0xFFE91E63); // وردي مشبع وحيوي (Rich Pink)
  static const Color primaryDark = Color(0xFFAD1457); // وردي غامق للعمق
  static const Color primaryLight = Color(0xFFF8BBD0); // وردي فاتح جداً

  // الخلفيات (تم توحيدها لتكون مسطحة ونظيفة)
  static const Color background = Color(0xFFF9F9F9); // رمادي فاتح جداً / أبيض مائل للرمادي
  static const Color softBackground = Color(0xFFF9F9F9);
  static const Color card = Color(0xFFFFFFFF); // أبيض نقي للبطاقات
  static const Color surface = Color(0xFFFFFFFF);

  // النصوص
  static const Color textPrimary = Color(0xFF5A2A3A); // بني غامق للنصوص الأساسية
  static const Color textSecondary = Color(0xFFA475B5); // بنفسجي فاتح للنصوص الثانوية

  // الذهبي / اللمسات
  static const Color gold = Color(0xFFC9A961);
  static const Color goldDark = Color(0xFFB7935F);
  static const Color goldLight = Color(0xFFE8D5A0);

  // حالات النظام
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFF5350);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);

  // الوضع الداكن (اختياري للمستقبل)
  static const Color darkBackground = Color(0xFF2A1A22);
  static const Color darkSurface = Color(0xFF3A2630);
  static const Color darkTextPrimary = Color(0xFFF5E6EC);
  static const Color darkTextSecondary = Color(0xFFC9A8B5);

  // أسماء قديمة للتوافق (لضمان عدم تعطل أي كود آخر)
  static const Color goldPrimary = gold;
  static const Color pinkAccent = primaryLight;
  static const Color creamSurface = card;
  static const Color lightBackground = background;
  static const Color lightSurface = card;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
}
