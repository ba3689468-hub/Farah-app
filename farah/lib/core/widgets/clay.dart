import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// مساعد Claymorphism: ظلال مزدوجة ناعمة (طينية)
/// استخدم: decoration: Clay.box(color: AppColors.card)
class Clay {
  Clay._();

  /// الظلال المزدوجة: أبيض أعلى-يسار + وردي غامق أسفل-يمين
  static List<BoxShadow> shadows({
    double blur = 18,
    double offset = 8,
    double darkAlpha = 0.20,
  }) {
    return [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.95),
        offset: Offset(-offset, -offset),
        blurRadius: blur,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: darkAlpha),
        offset: Offset(offset, offset),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  /// BoxDecoration طيني جاهز للبطاقات والحاويات
  static BoxDecoration box({Color? color, double radius = 28}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows(),
    );
  }

  /// نمط مضغوط (للأزرار عند الضغط)
  static BoxDecoration pressed({Color? color, double radius = 28}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.12),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  /// حاوية Clay جاهزة كـ Widget
  static Widget container({
    Widget? child,
    Color? color,
    double radius = 28,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: box(color: color, radius: radius),
      child: child,
    );
  }
}
