/// كيان المستخدم (يعبر عن البيانات في طبقة الـ Domain)
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role; // "user" | "provider" | "admin"
  final String? photoUrl;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.createdAt,
  });

  bool get isProvider => role == 'provider';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}
