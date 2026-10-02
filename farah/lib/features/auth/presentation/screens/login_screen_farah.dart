import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../hall_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FarahGlassLoginScreen extends ConsumerStatefulWidget {
  const FarahGlassLoginScreen({super.key});

  @override
  ConsumerState<FarahGlassLoginScreen> createState() =>
      _FarahGlassLoginScreenState();
}

class _FarahGlassLoginScreenState extends ConsumerState<FarahGlassLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  String? _error;

  static const Color gold = AppColors.primary;
  static const Color lightGold = AppColors.background;
  static const Color rose = AppColors.background;
  static const Color deepRose = AppColors.primary;
  static const Color cream = AppColors.background;
  static const Color chocolate = AppColors.primary;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signIn(_userCtrl.text.trim(), _passCtrl.text.trim());

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(fbUser.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'uid': fbUser.uid,
            'fullName': fbUser.displayName ?? 'مستخدم فرح',
            'email': fbUser.email ?? '',
            'phone': fbUser.phoneNumber ?? '',
            'role': 'user',
            'walletBalance': 0,
            'isVerified': true,
            'isBlocked': false,
            'fcmTokens': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HallListScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _error = _translateError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateError(String msg) {
    if (msg.contains('user-not-found')) return 'لا يوجد حساب بهذا البريد';
    if (msg.contains('wrong-password')) return 'كلمة المرور غير صحيحة';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('invalid-credential')) return 'بيانات الدخول غير صحيحة';
    if (msg.contains('too-many-requests')) return 'محاولات كثيرة، حاول لاحقاً';
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    return 'حدث خطأ، حاول مرة أخرى';
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(role: 'user'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: _buildGlassCard(context),
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 1.seconds)
          .slideY(begin: 0.1, end: 0.0, curve: Curves.easeOut),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(120),
                bottomLeft: Radius.circular(120),
                bottomRight: Radius.circular(80),
              ),
              border: Border.all(color: Colors.transparent, width: 1.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تم التحديث _ تسجيل الدخول',
                    style: TextStyle(
                        color: chocolate,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient:
                        const LinearGradient(colors: [gold, lightGold, gold]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                _glassField(
                  controller: _userCtrl,
                  hint: 'البريد الإلكتروني',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'البريد مطلوب';
                    if (!v.contains('@')) return 'بريد غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _glassField(
                  controller: _passCtrl,
                  hint: '••••••••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 6) return 'كلمة المرور قصيرة';
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: chocolate,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Checkbox(
                      value: _remember,
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _remember = v!),
                      activeColor: deepRose,
                      checkColor: Colors.white,
                      side: BorderSide(
                          color: chocolate.withValues(alpha: 0.6), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('تذكرني',
                      style: TextStyle(color: chocolate, fontSize: 13)),
                  const Spacer(),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('قريباً: استعادة كلمة المرور')),
                            );
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('نسيت كلمة المرور؟',
                        style: TextStyle(
                            color: deepRose,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: deepRose)),
                  ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 26),
                Container(
                  width: 200,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                        AppColors.background
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _loading ? null : _login,
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.celebration,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text('دخول',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          letterSpacing: 2)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('ليس لديك حساب؟ ',
                      style: TextStyle(
                          color: chocolate.withValues(alpha: 0.75), fontSize: 13)),
                  GestureDetector(
                    onTap: _loading ? null : _goToRegister,
                    child: const Text('أنشئ حساباً الآن',
                        style: TextStyle(
                            color: deepRose,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: deepRose)),
                  ),
                ]),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: gold, width: 2),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary,
                    AppColors.background
                  ],
                ).createShader(bounds),
                child: const Icon(Icons.person, size: 55, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              validator: validator,
              enabled: !_loading,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: chocolate, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    TextStyle(color: chocolate.withValues(alpha: 0.5), fontSize: 14),
                errorStyle: const TextStyle(
                    color: Colors.red, fontSize: 11, height: 0.8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffix != null) suffix,
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
