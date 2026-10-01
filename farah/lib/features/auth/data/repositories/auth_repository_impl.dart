import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> saveUserData(AppUser user) async {
    final model = UserModel(
      uid: user.uid,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      photoUrl: user.photoUrl,
    );
    await _firestore.collection('users').doc(user.uid).set(model.toFirestore());
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final current = _auth.currentUser;
    if (current == null) return null;

    final doc = await _firestore.collection('users').doc(current.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc.data()!, current.uid);
  }
}
