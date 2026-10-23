import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// ✅ مزود حالة الثيم (Theme Provider)
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await prefs.setBool('isDarkMode', true);
    } else {
      state = ThemeMode.light;
      await prefs.setBool('isDarkMode', false);
    }
  }
}

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
    final themeMode = ref.watch(themeProvider);
    const Color primaryColor = Color(0xFFD81B60); 

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

      // ✅ الثيم الفاتح
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // ... (باقي إعدادات الثيم القديمة)
      ),
      
      // ✅ الثيم الداكن (الوضع الليلي)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // ... (يمكنك إضافة ألوان أخرى للوضع الليلي هنا)
      ),

      themeMode: themeMode, // ✅ تطبيق الوضع المختار
      home: const OnboardingScreen(),
    );
  }
}
