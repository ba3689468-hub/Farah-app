import 'package:firebase_auth/firebase_auth.dart';
// ⚠️ تنبيه: تأكد من أن هذا المسار يطابق مكان ملف user_model.dart في مشروعك
// إذا ظهر خطأ في هذا السطر، احذفه وسأعطيك المسار الصحيح
import '../../data/models/user_model.dart'; 

abstract class AuthRepository {
  // ── دوال تسجيل الدخول وإنشاء الحساب التقليدية ──
  Future<UserCredential> signIn(String email, String password);
  
  Future<UserCredential> signUp(String email, String password);
  
  Future<void> saveUserData(UserModel user);

  // ── الدالة المفقودة التي تسبب الخطأ (جلب المستخدم الحالي) ──
  Future<User?> getCurrentUser(); 

  // ── دوال التحقق برمز OTP الجديدة ──
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  });

  Future<UserCredential?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  });
}
