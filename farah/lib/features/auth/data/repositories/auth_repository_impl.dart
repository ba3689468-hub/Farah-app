import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    // نستخدم Map مباشرة لتجنب مشاكل UserModel و AppUser
    await _firestore.collection('users').doc(userData['uid']).set({
      ...userData, // وضع كل البيانات المرسلة من الواجهة
      'walletBalance': 0,
      'isVerified': true,
      'isBlocked': false,
      'fcmTokens': [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
