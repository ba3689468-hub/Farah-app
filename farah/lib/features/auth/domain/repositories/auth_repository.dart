import 'package:firebase_auth/firebase_auth.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(String email, String password);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Future<void> saveUserData(AppUser user);
}
