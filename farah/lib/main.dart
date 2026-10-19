import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ تمت إضافة استيراد الخطوط

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

  // 🚀 تهيئة Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(options: webFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  // 🚀 تهيئة Supabase
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
    return MaterialApp(
      title: 'فرح',
      debugShowCheckedModeBanner: false,
      
      // --- إعدادات اللغة العربية (RTL) ---
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [
        Locale('ar', 'LY'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // -----------------------------------

      theme: ThemeData(
        primaryColor: const Color(0xFFD4AF37),
        // ✅ تغيير الخط الرسمي للتطبيق إلى Tajawal
        fontFamily: GoogleFonts.tajawal().fontFamily, 
      ),
      home: const OnboardingScreen(),
    );
  }
}
