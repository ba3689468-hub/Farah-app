import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'dart:io'; // ✅ ضروري لـ HttpOverrides

// 🟩 إعدادات Firebase
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
  authDomain: "farah-app-caa99.firebaseapp.com",
  projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  storageBucket: "farah-app-caa99.firebasestorage.app",
  messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
  appId: String.fromEnvironment('FIREBASE_APP_ID'),
  measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
);

// 🟩 إعدادات Supabase
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ إجبار التطبيق على استخدام IPv4 لحل مشاكل الاتصال (Failed host lookup)
  HttpOverrides.global = _MyHttpOverrides();

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

// ✅ كلاس إجبار الاتصال عبر IPv4
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class FarahApp extends ConsumerWidget {
  const FarahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
