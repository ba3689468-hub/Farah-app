import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../data/models/user_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String _selectedRole = 'user';

  static const Color gold      = Color(0xFFC0392B);
  static const Color lightGold = Color(0xFFEDEEE9);
  static const Color rose      = Color(0xFFEDEEE9);
  static const Color deepRose  = Color(0xFFC0392B);
  static const Color cream     = Color(0xFFF5EBE1);
  static const Color chocolate = Color(0xFFC0392B);

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      await repo.saveUserData(UserModel(
        uid: cred.user!.uid,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: '+218${_phoneCtrl.text.trim()}',
        role: _selectedRole,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء حسابك بنجاح! يمكنك تسجيل الدخول الآن'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = _translateError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateError(String msg) {
    if (msg.contains('email-already-in-use')) return 'هذا البريد مسجّل مسبقاً';
    if (msg.contains('invalid-email')) return 'البريد الإلكتروني غير صالح';
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    return 'حدث خطأ، حاول مرة أخرى';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5EBE1), Color(0xFFEDEEE9), Color(0xFFA93226)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // زر الرجوع
              Positioned(
                top: 10, right: 20,
                child: Material(
                  color: Colors.white.withOpacity(0.3),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: chocolate),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Form(
                    key: _formKey,
                    child: _buildGlassCard(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: -20, left: 20, right: 20,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: deepRose.withOpacity(0.6), blurRadius: 60, spreadRadius: 10)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cream.withOpacity(0.85), rose.withOpacity(0.75)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(120),
                bottomLeft: Radius.circular(120),
                bottomRight: Radius.circular(80),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.4),
              boxShadow: [BoxShadow(color: deepRose.withOpacity(0.35), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('إنشاء حساب',
                  style: TextStyle(color: chocolate, fontSize: 28, fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.white54, blurRadius: 6, offset: Offset(0, 2))])),
                const SizedBox(height: 6),
                Container(
                  width: 60, height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gold, lightGold, gold]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // ── الاسم ──
                _glassField(
                  controller: _nameCtrl,
                  hint: 'الاسم الكامل',
                  icon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                    if (v.trim().length < 3) return 'الاسم قصير';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── البريد ──
                _glassField(
                  controller: _emailCtrl,
                  hint: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'البريد مطلوب';
                    if (!v.contains('@')) return 'بريد غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── الهاتف ──
                _glassField(
                  controller: _phoneCtrl,
                  hint: 'رقم الهاتف (مثال: 91xxxxxxx)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'الهاتف مطلوب';
                    if (v.length < 9) return 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── كلمة المرور ──
                _glassField(
                  controller: _passCtrl,
                  hint: '••••••••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                    if (v.length < 6) return 'كلمة المرور قصيرة (6+)';
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: chocolate, size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 18),

                // ── نوع الحساب ──
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('نوع الحساب:',
                    style: TextStyle(color: chocolate, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _roleCard(
                      value: 'user',
                      icon: Icons.person,
                      title: 'زبون',
                      subtitle: 'أبحث عن خدمة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleCard(
                      value: 'provider',
                      icon: Icons.storefront,
                      title: 'مزوّد خدمة',
                      subtitle: 'صالة / متجر',
                    ),
                  ),
                ]),

                // ── خطأ ──
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),

                // ── زر إنشاء حساب ──
                Container(
                  width: 220, height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC0392B), Color(0xFFA93226), Color(0xFFEDEEE9)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: gold.withOpacity(0.55), blurRadius: 22, offset: const Offset(0, 8))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _loading ? null : _register,
                      child: Center(
                        child: _loading
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('إنشاء حساب',
                                  style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16, letterSpacing: 1)),
                              ],
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── رابط تسجيل الدخول ──
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('لديك حساب بالفعل؟ ',
                    style: TextStyle(color: chocolate.withOpacity(0.75), fontSize: 13)),
                  GestureDetector(
                    onTap: _loading ? null : () => Navigator.pop(context),
                    child: const Text('سجّل دخول',
                      style: TextStyle(color: deepRose, fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: deepRose)),
                  ),
                ]),
              ],
            ),
          ),
        ),

        // ── أيقونة الافتتاح في الأعلى ──
        Positioned(
          top: 0,
          child: Container(
            width: 95, height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white,
              border: Border.all(color: gold, width: 2),
              boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFC0392B), Color(0xFFC0392B), Color(0xFFEDEEE9)],
                ).createShader(bounds),
                child: const Icon(Icons.person_add, size: 55, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── بطاقة اختيار الدور ──
  Widget _roleCard({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: _loading ? null : () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? gold.withOpacity(0.25) : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? gold : Colors.white.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
            ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? deepRose : chocolate.withOpacity(0.6), size: 28),
            const SizedBox(height: 6),
            Text(title,
              style: TextStyle(
                color: isSelected ? chocolate : chocolate.withOpacity(0.7),
                fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: TextStyle(
                color: chocolate.withOpacity(0.55),
                fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── حقل زجاجي ──
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [BoxShadow(color: deepRose.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const SizedBox(width: 6),
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC0392B), Color(0xFFC0392B), Color(0xFFEDEEE9)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: gold.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 3))],
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
            style: const TextStyle(color: chocolate, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: chocolate.withOpacity(0.55), fontSize: 13),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 11, height: 0.8),
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
      ]),
    );
  }
}