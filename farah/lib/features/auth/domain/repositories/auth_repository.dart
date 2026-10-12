import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(String email, String password);
  Future<void> saveUserData(dynamic user); // dynamic لتجنب مشاكل المسارات
  Future<User?> getCurrentUser(); 
  // تم إلغاء دوال OTP مؤقتاً
}
