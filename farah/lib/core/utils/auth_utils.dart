class AuthUtils {
  static String getFakeEmail(String phone) {
    String cleaned = phone.replaceAll('+218', '').replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    cleaned = cleaned.replaceAll(RegExp(r'^0+'), '');
    return '$cleaned@farah.app';
  }
}
