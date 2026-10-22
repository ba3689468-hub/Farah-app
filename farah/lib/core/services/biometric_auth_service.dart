import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
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
  Future<bool> enableBiometrics(String phone, String password) async {
    try {
      // ✅ تم إزالة biometricOnly: true لأن الإصدارات الحديثة لا تدعمها
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'قم بتأكيد بصمتك لتفعيل الدخول السريع',
        stickyAuth: true,
      );
      
      if (didAuthenticate) {
        await _storage.write(key: _keyPhone, value: phone);
        await _storage.write(key: _keyPassword, value: password);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 3. تعطيل البصمة ومسح البيانات المحفوظة
  Future<void> disableBiometrics() async {
    await _storage.delete(key: _keyPhone);
    await _storage.delete(key: _keyPassword);
  }

  /// 4. التحقق من البصمة واسترجاع البيانات لتسجيل الدخول
  Future<Map<String, String>?> loginWithBiometrics() async {
    try {
      // ✅ تم إزالة biometricOnly: true هنا أيضاً
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'قم بتأكيد بصمتك لتسجيل الدخول',
        stickyAuth: true,
      );
      
      if (didAuthenticate) {
        final phone = await _storage.read(key: _keyPhone);
        final password = await _storage.read(key: _keyPassword);
        
        if (phone != null && password != null) {
          return {'phone': phone, 'password': password};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 5. التحقق من وجود بيانات محفوظة مسبقاً
  Future<bool> hasSavedCredentials() async {
    final phone = await _storage.read(key: _keyPhone);
    return phone != null;
  }
}
