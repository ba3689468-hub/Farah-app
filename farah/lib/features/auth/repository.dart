import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إرسال رمز التحقق OTP إلى رقم الهاتف
  Future<void> verifyPhoneNumber({
    required String phoneNumber, // مثال: +218910000000
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

  /// التحقق من الرمز وتسجيل الدخول
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
