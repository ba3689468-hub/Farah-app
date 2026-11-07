class AuthUtils {
  static String getFakeEmail(String phone) {
    // إزالة أي رموز أو مسافات
    String cleaned = phone.replaceAll('+218', '').replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    // إزالة الأصفار من البداية
    cleaned = cleaned.replaceAll(RegExp(r'^0+'), '');
    return '$cleaned@farah.app';
  }
}
