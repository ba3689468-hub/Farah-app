import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── تهيئة Firebase ──
  try {
    await Firebase.initializeApp();
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(body: Center(child: Text('فشل Firebase: $e')))));
    return;
  }

  // ── تهيئة Supabase ──
  await Supabase.initialize(
    url: 'https://tzizhccygtgqbgkhbwif.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6aXpoY2N5Z3RncWJna2hid2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE2Mzk0NDEsImV4cCI6MjEwNzIxNTQ0MX0.im5_c5MMQgnUYLwRIuzS_SJKObyVPLW5PPBjOtvmUR0',
  );

  runApp(const ProviderScope(child: FarahApp()));
}

class FarahApp extends StatelessWidget {
  const FarahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      locale: const Locale('ar', 'LY'),
      supportedLocales: const [Locale('ar', 'LY'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const OnboardingScreen(),
    );
  }
}
