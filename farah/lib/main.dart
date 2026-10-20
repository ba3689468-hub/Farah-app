import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

// 🟩 استيراد شاشة الترحيب الأولى
import 'features/onboarding/onboarding_screen.dart';

//
// 🔵 إعدادات Firebase
//
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCSqBeVcXBQouswQlzqIDFb4fLXbHEzg",
  authDomain: "farah-app-caa99.firebaseapp.com",
  projectId: "farah-app-caa99",
  storageBucket: "farah-app-caa99.firebasestorage.app",
  messagingSenderId: "665183433574",
  appId: "1:665183433574:web:76bdc78d836fd6cecea7",
  measurementId: "G-G7987HVMLD",
);

//
// 🔵 إعدادات Supabase
//
const String supabaseUrl = 'https://tzizhccygtgqbkghbwif.supabase.co';
const String supabaseAnonKey = 'sb_publishable_HxGzyPlKTAUK5U7Rznlf0Q_EY0du155';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: webFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: FarahApp(),
    ),
  );
}

class FarahApp extends StatelessWidget {
  const FarahApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ اللون الأساسي للتطبيق (يمكنك تغييره من هنا ليتغير في كل التطبيق)
    const Color primaryColor = Color(0xFFD81B60); 
    const Color secondaryColor = Color(0xFFD4AF37);

    return MaterialApp(
      title: 'فرح',
      debugShowCheckedModeBanner: false,
      
      // إعدادات اللغة العربية
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [Locale('ar', 'LY'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🎨 الثيم العام للتطبيق (Global Theme)
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // خلفية رمادية فاتحة مريحة للعين
        fontFamily: GoogleFonts.tajawal().fontFamily,
        
        // 1. توحيد تصميم شريط التطبيق العلوي (App Bar)
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Tajawal', // سيأخذ خط Tajawal تلقائياً
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // 2. توحيد تصميم الأزرار الأساسية (Elevated Button)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55), // العرض الكامل والارتفاع الموحد
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // حواف دائرية موحدة
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
            elevation: 2,
            shadowColor: primaryColor.withValues(alpha: 0.4),
          ),
        ),

        // 3. توحيد تصميم حقول الإدخال (Text Fields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),

        // 4. توحيد تصميم البطاقات (Cards)
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      home: const OnboardingScreen(),
    );
  }
}
