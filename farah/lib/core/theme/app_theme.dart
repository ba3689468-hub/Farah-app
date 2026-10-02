import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

// زوايا دائرية كبيرة، ظلال ناعمة، ألوان باستيل: Claymorphism
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.tajawalTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      
      // ==========================================
      // 1. تغيير لون الخلفية لجميع الشاشات
      // ==========================================
      // يمكنك تغيير اللون (0xFFF9F9F9) إلى أي لون تريده (مثلاً Colors.white)
      scaffoldBackgroundColor: const Color(0xFFF9F9F9), 

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      
      // ==========================================
      // 2. إزالة التوهج من الشريط العلوي (AppBar)
      // ==========================================
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF9F9F9), // نفس لون الخلفية
        foregroundColor: AppColors.textPrimary,
        elevation: 0, // <--- إزالة الظل
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      
      // ==========================================
      // 3. إزالة التوهج من الأزرار (Buttons)
      // ==========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0, // <--- إزالة الظل
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // ==========================================
      // 4. إزالة التوهج من البطاقات (Cards)
      // ==========================================
      cardTheme: CardThemeData(
        elevation: 0, // <--- إزالة الظل
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          // إضافة حدود خفيفة جداً بدلاً من الظل لتعطي شكلاً مرتباً
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
      ),
      
      // ==========================================
      // 5. إزالة التوهج من حقول الإدخال (Text Fields)
      // ==========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }
}
