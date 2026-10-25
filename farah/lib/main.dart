import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/onboarding/onboarding_screen.dart';

// 🟩 إعدادات Firebase
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCSqBeVcXBQouswQlzqIDFb4fLXbHEzg",
  authDomain: "farah-app-caa99.firebaseapp.com",
  projectId: "farah-app-caa99",
  storageBucket: "farah-app-caa99.firebasestorage.app",
  messagingSenderId: "665183433574",
  appId: "1:665183433574:web:76bdc78d836fd6cecea7",
  measurementId: "G-G7987HVMLD",
);

// 🟩 إعدادات Supabase
const String supabaseUrl = 'https://tzizhccygtgqbkghbwif.supabase.co';
const String supabaseAnonKey = 'sb_publishable_HxGzyPlKTAUK5U7Rznlf0Q_EY0du155';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: webFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    const ProviderScope(
      child: FarahApp(),
    ),
  );
}

class FarahApp extends ConsumerWidget {
  const FarahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color primaryColor = Color(0xFFD81B60); 

    // ✅ توحيد الخط لكل عناصر التطبيق باستخدام TextTheme
    final textTheme = GoogleFonts.tajawalTextTheme();

    return MaterialApp(
      title: 'فرح',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [Locale('ar', 'LY'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ✅ ثيم موحد (فاتح فقط - بدون وضع ليلي)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        textTheme: textTheme.apply(
          fontFamily: GoogleFonts.tajawal().fontFamily,
          bodyColor: const Color(0xFF1A1A1A), // لون النص الأساسي
          displayColor: const Color(0xFF1A1A1A),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ),

      // ✅ إزالة الوضع الليلي (لا يوجد darkTheme، لا يوجد themeMode)
      home: const OnboardingScreen(),
    );
  }
}
