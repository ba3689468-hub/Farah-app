import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen_farah.dart';
import '../../hall_list_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _loadSeen();
  }

  Future<void> _loadSeen() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _seenOnboarding = p.getBool('seen_onboarding') ?? false);
  }

  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('seen_onboarding', true);
    if (!mounted) return;
    setState(() => _seenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
      data: (fbUser) {
        if (fbUser == null) {
          if (_seenOnboarding == false) {
            return OnboardingScreen(onFinish: _markSeen);
          }
          return const FarahGlassLoginScreen();
        }
        final userAsync = ref.watch(currentUserProvider);
        return userAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
          data: (user) {
            if (user == null) {
              _createDoc(fbUser);
              return const HallListScreen();
            }
            if (user.isProvider) return const _ProviderPlaceholder();
            return const HallListScreen();
          },
        );
      },
    );
  }

  static Future<void> _createDoc(User fu) async {
    try {
      final r = FirebaseFirestore.instance.collection('users').doc(fu.uid);
      final s = await r.get();
      if (!s.exists) {
        await r.set({
          'uid': fu.uid,
          'fullName': fu.displayName ?? 'مستخدم فرح',
          'email': fu.email ?? '',
          'phone': fu.phoneNumber ?? '',
          'role': 'user',
          'walletBalance': 0,
          'isVerified': true,
          'isBlocked': false,
          'fcmTokens': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }
}

class _ProviderPlaceholder extends StatelessWidget {
  const _ProviderPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المزود')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.amber),
            SizedBox(height: 20),
            Text('لوحة المزود قيد الإنشاء حالياً',
                style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
