import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen_farah.dart';
import '../../hall_list_screen.dart';

// شاشة البداية الذكية: تقرأ حالة المستخدم ودوره وتوجهه
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('خطأ: $e')),
      ),
      data: (firebaseUser) {
        // لم يسجل الدخول → شاشة الدخول الجديدة
        if (firebaseUser == null) {
          return const FarahGlassLoginScreen();
        }
        // سجل الدخول → اقرأ الدور
        final userAsync = ref.watch(currentUserProvider);
        return userAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(body: Center(child: Text('خطأ: $e'))),
          data: (user) {
            if (user == null) return const FarahGlassLoginScreen();
            if (user.isProvider) {
              return const _ProviderPlaceholder();
            }
            return const HallListScreen();
          },
        );
      },
    );
  }
}

// لوحة المزود (قيد الإنشاء حالياً)
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