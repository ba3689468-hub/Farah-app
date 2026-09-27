import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

// مزود المستودع
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// مزود حالة المصادقة (Stream يتابع تغييرات تسجيل الدخول)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// مزود بيانات المستخدم الحالي (مع الدور)
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getCurrentUser();
});
