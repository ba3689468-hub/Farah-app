import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// مساعد Claymorphism ناعم
class Clay {
  Clay._();

  static List<BoxShadow> shadows({
    double blur = 14,
    double offset = 6,
    double darkAlpha = 0.15,
  }) {
    return [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.55),
        offset: Offset(-offset, -offset),
        blurRadius: blur,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: darkAlpha),
        offset: Offset(offset, offset),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  static BoxDecoration box({Color? color, double radius = 28}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows(),
    );
  }

  static BoxDecoration pressed({Color? color, double radius = 28}) {
    return BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.10),
          offset: const Offset(2, 2),
          blurRadius: 5,
        ),
      ],
    );
  }

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
