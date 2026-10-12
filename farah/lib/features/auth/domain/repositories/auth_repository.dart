import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ⚠️ تأكد من أن مسار UserModel صحيح بالنسبة لمشروعك، قد تحتاج لتعديله إذا كان في مجلد آخر
import '../../data/models/user_model.dart'; 

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── 1. تسجيل الدخول التقليدي (بالبريد الوهمي وكلمة المرور) ──
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── 2. إنشاء حساب جديد ──
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── 3. حفظ بيانات المستخدم في Firestore ──
  Future<void> saveUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'role': user.role,
      'walletBalance': 0,
      'isVerified': true,
      'isBlocked': false,
      'fcmTokens': [],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── 4. إرسال رمز التحقق OTP (جديد) ──
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // في أندرويد: أحياناً يتم التحقق تلقائياً دون إدخال الرمز
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'حدث خطأ في إرسال الرمز');
        },
        codeSent: (String verificationId, int? resendToken) {
          // تم إرسال الرمز بنجاح
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // انتهت مهلة القراءة التلقائية
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // ── 5. التحقق من رمز OTP وتسجيل الدخول (جديد) ──
  Future<UserCredential?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      return null; // فشل التحقق
    }
  }
}
