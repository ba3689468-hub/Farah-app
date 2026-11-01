import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // إعدادات التخزين الآمن
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyPhone = 'bio_phone';
  static const String _keyPassword = 'bio_password';

  /// 1. التحقق من دعم الجهاز للبصمة
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// 2. تفعيل البصمة وحفظ بيانات الدخول
  /// ✅ الحل الجذري: لا نطلب من المستخدم مسح بصمته هنا! 
  /// بل نقوم بحفظ البيانات مباشرة في الخلفية لتجنب تعليق التطبيق.
  Future<bool> enableBiometrics(String phone, String password) async {
    try {
      await _storage.write(key: _keyPhone, value: phone).timeout(const Duration(seconds: 5));
      await _storage.write(key: _keyPassword, value: password).timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint("Biometric enable error: $e");
      return false;
    }
  }

  /// 3. تعطيل البصمة ومسح البيانات المحفوظة
  Future<void> disableBiometrics() async {
    try {
      await _storage.delete(key: _keyPhone);
      await _storage.delete(key: _keyPassword);
    } catch (e) {
      debugPrint("Error disabling biometrics: $e");
    }
  }

  /// 4. التحقق من البصمة واسترجاع البيانات لتسجيل الدخول
  /// يتم طلب البصمة فقط هنا (عند الضغط على أيقونة البصمة للدخول)
  Future<Map<String, String>?> loginWithBiometrics() async {
    try {
      await _localAuth.stopAuthentication(); // إيقاف أي عملية سابقة عالقة

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'قم بتأكيد بصمتك لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,           // يمنع التجمد عند العودة من الخلفية
          sensitiveTransaction: false, // يمنع التجمد في أندرويد 12+
          biometricOnly: true,         // إجبار استخدام البصمة فقط لتجنب نافذة PIN
          useErrorDialogs: true,
        ),
      ).timeout(const Duration(seconds: 10)); // مهلة زمنية لمنع التعليق
      
      if (didAuthenticate) {
        final phone = await _storage.read(key: _keyPhone).timeout(const Duration(seconds: 5));
        final password = await _storage.read(key: _keyPassword).timeout(const Duration(seconds: 5));
        
        if (phone != null && password != null) {
          return {'phone': phone, 'password': password};
        }
      }
      return null;
    } catch (e) {
      debugPrint("Biometric login error: $e");
      return null;
    }
  }

  /// 5. التحقق من وجود بيانات محفوظة مسبقاً
  Future<bool> hasSavedCredentials() async {
    try {
      final phone = await _storage.read(key: _keyPhone).timeout(const Duration(seconds: 3));
      return phone != null;
    } catch (e) {
      return false;
    }
  }
}
