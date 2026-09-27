import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen_farah.dart';
import '../../hall_list_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
      data: (fbUser) {
        if (fbUser == null) return const FarahGlassLoginScreen();
        final userAsync = ref.watch(currentUserProvider);
        return userAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
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
            Text('لوحة المزود قيد الإنشاء حالياً', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}