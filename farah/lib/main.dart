import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/screens/login_screen_farah.dart';
// ═══════════════════════════════════════════════════════════
// 🆕 إعدادات Firebase للويب
// ═══════════════════════════════════════════════════════════
const FirebaseOptions webFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCSqBeVcxBQBusowTlzqidEb4fLXxbHEzg",
  authDomain: "farah-app-caa99.firebaseapp.com",
  projectId: "farah-app-caa99",
  storageBucket: "farah-app-caa99.firebasestorage.app",
  messagingSenderId: "665183433574",
  appId: "1:665183433574:web:76bdcc78d836fd6ceccea7",
  measurementId: "G-Q79B7HVMLD",
);

// ═══════════════════════════════════════════════════════════
// 🆕 إعدادات Supabase
// ═══════════════════════════════════════════════════════════
const String supabaseUrl = 'https://tzizhccygtgqbkgkhbwif.supabase.co';
const String supabaseAnonKey = sb_publishable_HxGzyPlkTAUk5U7Rznlf0Q_EY0dui55 

// ⚠️ استبدل anonKey بمفتاحك الحقيقي من Supabase:
// Dashboard → Settings → API → anon/public

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════
  // تهيئة Firebase (يستخدم إعدادات الويب للويب، والجوال للموبايل)
  // ═══════════════════════════════════════════════════════════
  if (kIsWeb) {
    await Firebase.initializeApp(options: webFirebaseOptions);
  } else {
    await Firebase.initializeApp();
  }

  // ═══════════════════════════════════════════════════════════
  // تهيئة Supabase
  // ═══════════════════════════════════════════════════════════
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
      theme: ThemeData(
        primaryColor: const Color(0xFFD4AF37),
        fontFamily: 'Cairo',
      ),
      home: const FarahGlassLoginScreen(),
    );
  }
}
