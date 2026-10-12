import 'dart:async';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String _selectedRole = 'user';

  bool _isOtpSent = false;
  final String _fakeCode = "123456";

  int _timerSeconds = 60;
  Timer? _timer;

  static const Color gold = AppColors.primary;
  static const Color lightGold = AppColors.background;
  static const Color deepRose = AppColors.primary;
  static const Color chocolate = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timerSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _timerSeconds--);
      }
    });
  }

  Future<void> _register() async {
    if (!_isOtpSent) {
      if (!_formKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      setState(() { _loading = true; _error = null; });

      await Future.delayed(const Duration(seconds: 1));

      setState(() { _isOtpSent = true; _loading = false; });
      _startResendTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال رمز وهمي (استخدم $_fakeCode)'), backgroundColor: Colors.green),
      );
      return;
    }

    if (_otpCtrl.text.trim() != _fakeCode) {
      setState(() => _error = 'الرمز غير صحيح، استخدم $_fakeCode');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final phone = _phoneCtrl.text.trim();
      final fakeEmail = '$phone@farah.app';

      final cred = await repo.signUp(fakeEmail, _passCtrl.text.trim());

      await repo.saveUserData({
        'uid': cred.user!.uid,
        'fullName': _nameCtrl.text.trim(),
        'email': fakeEmail,
        'phone': '+218$phone',
        'role': _selectedRole,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء حسابك بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'حدث خطأ: تأكد من أن الرقم غير مسجل مسبقاً');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resendCode() {
    if (_timerSeconds > 0) return;
    setState(() { _loading = true; _error = null; });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _loading = false);
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إعادة إرسال الرمز الوهمي ($_fakeCode)'), backgroundColor: Colors.green),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10, right: 20,
              child: Material(
                color: Colors.transparent, shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 22),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(key: _formKey, child: _buildGlassCard(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(80), topRight: Radius.circular(120), bottomLeft: Radius.circular(120), bottomRight: Radius.circular(80)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isOtpSent ? 'تأكيد رقم الهاتف' : 'إنشاء حساب', style: const TextStyle(color: chocolate, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(width: 60, height: 2, decoration: BoxDecoration(gradient: const LinearGradient(colors: [gold, lightGold, gold]), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),

                _buildField(controller: _nameCtrl, hint: 'الاسم الكامل', icon: Icons.person_outline, enabled: !_isOtpSent, validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
                const SizedBox(height: 18),
                _buildField(controller: _phoneCtrl, hint: '9X XXXXXXX', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, digitsOnly: true, maxLength: 10, enabled: !_isOtpSent, validator: (v) => (v == null || v.length < 10) ? 'رقم الهاتف يجب أن يكون 10 أرقام' : null),
                const SizedBox(height: 18),
                _buildField(controller: _passCtrl, hint: '••••••••••••••', icon: Icons.lock_outline, obscure: _obscure, enabled: !_isOtpSent, validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور قصيرة' : null, toggle: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: chocolate, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
                const SizedBox(height: 18),
                _buildField(controller: _confirmPassCtrl, hint: 'تأكيد كلمة المرور', icon: Icons.lock_reset_outlined, obscure: _obscureConfirm, enabled: !_isOtpSent, validator: (v) => (v != _passCtrl.text) ? 'كلمة المرور غير متطابقة' : null, toggle: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: chocolate, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                const SizedBox(height: 18),

                if (!_isOtpSent) ...[
                  const Align(alignment: Alignment.centerRight, child: Text('نوع الحساب:', style: TextStyle(color: chocolate, fontSize: 14, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _roleCard(value: 'user', icon: Icons.person, title: 'زبون', subtitle: 'أبحث عن خدمة', enabled: !_isOtpSent)),
                    const SizedBox(width: 12),
                    Expanded(child: _roleCard(value: 'provider', icon: Icons.storefront, title: 'مزوّد خدمة', subtitle: 'صالة / متجر', enabled: !_isOtpSent)),
                  ]),
                ],

                if (_isOtpSent) ...[
                  const SizedBox(height: 18),
                  _buildField(controller: _otpCtrl, hint: '------', icon: Icons.message_outlined, keyboardType: TextInputType.number, digitsOnly: true, maxLength: 6, validator: (v) => (v == null || v.length < 6) ? 'رمز التحقق مطلوب' : null),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _timerSeconds > 0 ? null : _resendCode,
                        child: Text(
                          _timerSeconds > 0 ? 'إعادة الإرسال بعد $_timerSeconds ث' : 'إعادة إرسال الرمز',
                          style: TextStyle(color: _timerSeconds > 0 ? Colors.grey : deepRose, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading ? null : () {
                          _timer?.cancel();
                          setState(() { _isOtpSent = false; _otpCtrl.clear(); _error = null; });
                        },
                        child: const Text('الرقم غير صحيح؟ تعديل', style: TextStyle(color: deepRose, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.4))), child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))])),
                ],
                const SizedBox(height: 24),

                Container(
                  width: 220, height: 54,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(30)),
                  child: Material(color: Colors.transparent, child: InkWell(
                    borderRadius: BorderRadius.circular(30), onTap: _loading ? null : _register,
                    child: Center(child: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_isOtpSent ? Icons.check_circle_outline : Icons.person_add_alt_1, color: Colors.white, size: 20), const SizedBox(width: 10), Text(_isOtpSent ? 'تأكيد وإنشاء' : 'إنشاء حساب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))])),
                  )),
                ),
                const SizedBox(height: 18),
                if (!_isOtpSent) Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('لديك حساب بالفعل؟ ', style: TextStyle(color: chocolate.withValues(alpha: 0.75), fontSize: 13)), GestureDetector(onTap: _loading ? null : () => Navigator.pop(context), child: const Text('سجّل دخول', style: TextStyle(color: deepRose, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))) ]),
              ],
            ),
          ),
        ),
        Positioned(top: 0, child: Container(width: 95, height: 95, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: gold, width: 2), boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]), child: Center(child: Icon(_isOtpSent ? Icons.sms_outlined : Icons.person_add, size: 55, color: AppColors.primary)))),
      ],
    );
  }

  Widget _roleCard({required String value, required IconData icon, required String title, required String subtitle, required bool enabled}) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: (!enabled || _loading) ? null : () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: isSelected ? gold.withValues(alpha: 0.15) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: isSelected ? gold : Colors.black.withValues(alpha: 0.1), width: isSelected ? 2 : 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isSelected ? deepRose : chocolate.withValues(alpha: 0.6), size: 28),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: isSelected ? chocolate : chocolate.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: chocolate.withValues(alpha: 0.55), fontSize: 10)),
        ]),
      ),
    );
  }

  // 🛠️ التعديل: جعل الخلفية بيضاء دائماً، وتغيير لون النص فقط عند التعطيل
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? toggle,
    TextInputType? keyboardType,
    bool digitsOnly = false,
    int? maxLength,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled && !_loading,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      maxLength: maxLength,
      inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: TextStyle(
        // لون النص يتغير إلى رمادي فاتح عند التعطيل
        color: enabled ? chocolate : chocolate.withValues(alpha: 0.3),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: chocolate.withValues(alpha: 0.5), fontSize: 14),
        counterText: '',
        errorStyle: const TextStyle(color: Colors.red, fontSize: 11, height: 0.8),
        filled: true,
        // ✅ التعديل هنا: الخلفية تظل بيضاء دائماً
        fillColor: Colors.white, 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        
        prefixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 60),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              // الأيقونة تظل ملونة حتى عند التعطيل لتبدو جميلة
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        
        suffixIcon: toggle,
      ),
    );
  }
}
