import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _otpCtrl = TextEditingController(); // حقل رمز التحقق الجديد

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String _selectedRole = 'user';

  // متغيرات OTP
  bool _isOtpSent = false;
  String? _verificationId;

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
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // المرحلة 1: إرسال الرمز
    if (!_isOtpSent) {
      if (!_formKey.currentState!.validate()) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _loading = true;
        _error = null;
      });

      String phone = _phoneCtrl.text.trim();
      // إضافة مقدمة الدولة (ليبيا +218)
      if (!phone.startsWith('+218')) {
        phone = '+218$phone';
      }

      final repo = ref.read(authRepositoryProvider);
      await repo.verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (verId) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verId;
            _loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رمز التحقق، يرجى إدخاله'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (err) {
          setState(() {
            _loading = false;
            _error = _translateError(err);
          });
        },
      );
      return;
    }

    // المرحلة 2: التحقق من الرمز وإنشاء الحساب
    if (_otpCtrl.text.trim().length < 6) {
      setState(() => _error = 'الرجاء إدخال رمز مكوّن من 6 أرقام');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);

      // 1. التحقق من رمز OTP
      final otpCred = await repo.signInWithOTP(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );

      if (otpCred == null || otpCred.user == null) {
        throw Exception('الرمز غير صحيح أو انتهت صلاحيته');
      }

      // 2. تم التحقق بنجاح، الآن ننشئ الحساب الفعلي بالبريد الوهمي
      final phone = _phoneCtrl.text.trim();
      final fakeEmail = '$phone@farah.app';

      final cred = await repo.signUp(
        fakeEmail,
        _passCtrl.text.trim(),
      );

      // 3. حفظ بيانات المستخدم في Firestore
      await repo.saveUserData(UserModel(
        uid: cred.user!.uid,
        fullName: _nameCtrl.text.trim(),
        email: fakeEmail,
        phone: '+218$phone',
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
        // العودة إلى شاشة تسجيل الدخول
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = _translateError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateError(String msg) {
    if (msg.contains('email-already-in-use')) return 'هذا الرقم مسجّل مسبقاً';
    if (msg.contains('invalid-email')) return 'رقم الهاتف غير صالح';
    if (msg.contains('weak-password')) return 'كلمة المرور ضعيفة جداً';
    if (msg.contains('network-request-failed')) return 'تحقق من اتصال الإنترنت';
    if (msg.contains('invalid-verification-code')) return 'رمز التحقق غير صحيح';
    if (msg.contains('session-expired')) return 'انتهت الجلسة، أعد إرسال الرمز';
    if (msg.contains('quota-exceeded')) return 'تم استهلاك حصة الرسائل اليومية';
    return msg.length > 50 ? 'حدث خطأ، حاول مرة أخرى' : msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── زر الرجوع ──
            Positioned(
              top: 10,
              right: 20,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── العنوان ──
                Text(
                  _isOtpSent ? 'تأكيد رقم الهاتف' : 'إنشاء حساب',
                  style: const TextStyle(
                    color: chocolate,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // ── الخط الفاصل ──
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [gold, lightGold, gold],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // ── حقل الاسم ──
                if (!_isOtpSent)
                  _buildField(
                    controller: _nameCtrl,
                    hint: 'الاسم الكامل',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                      if (v.trim().length < 3) return 'الاسم قصير';
                      return null;
                    },
                  ),
                if (!_isOtpSent) const SizedBox(height: 14),

                // ── حقل رقم الهاتف ──
                _buildField(
                  controller: _phoneCtrl,
                  hint: '9X XXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  digitsOnly: true,
                  maxLength: 10,
                  enabled: !_isOtpSent, // تعطيل الحقل عند إرسال الرمز
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'رقم الهاتف مطلوب';
                    if (v.length < 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── حقول كلمة المرور (تختفي عند إرسال الرمز) ──
                if (!_isOtpSent) ...[
                  _buildField(
                    controller: _passCtrl,
                    hint: '••••••••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 6) return 'كلمة المرور قصيرة (6+)';
                      return null;
                    },
                    toggle: IconButton(
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
                  _buildField(
                    controller: _confirmPassCtrl,
                    hint: 'تأكيد كلمة المرور',
                    icon: Icons.lock_reset_outlined,
                    obscure: _obscureConfirm,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'تأكيد كلمة المرور مطلوب';
                      }
                      if (v != _passCtrl.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                    toggle: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: chocolate,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── نوع الحساب ──
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'نوع الحساب:',
                      style: TextStyle(
                        color: chocolate,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
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
                    ],
                  ),
                ],

                // ── حقل إدخال رمز OTP (يظهر فقط عند إرسال الرمز) ──
                if (_isOtpSent) ...[
                  _buildField(
                    controller: _otpCtrl,
                    hint: '------',
                    icon: Icons.message_outlined,
                    keyboardType: TextInputType.number,
                    digitsOnly: true,
                    maxLength: 6,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'رمز التحقق مطلوب';
                      if (v.length < 6) return 'الرمز يجب أن يكون 6 أرقام';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // زر لتعديل الرقم في حال الخطأ
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _isOtpSent = false;
                              _otpCtrl.clear();
                              _error = null;
                            });
                          },
                    child: const Text(
                      'الرقم غير صحيح؟ تعديل الرقم',
                      style: TextStyle(
                        color: deepRose,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],

                // ── رسالة الخطأ ──
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── زر الإجراء (إنشاء حساب / تأكيد الرمز) ──
                Container(
                  width: 220,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _loading ? null : _register,
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isOtpSent
                                        ? Icons.check_circle_outline
                                        : Icons.person_add_alt_1,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isOtpSent ? 'تأكيد وإنشاء' : 'إنشاء حساب',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── رابط تسجيل الدخول ──
                if (!_isOtpSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(
                          color: chocolate.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'سجّل دخول',
                          style: TextStyle(
                            color: deepRose,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: deepRose,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // ── الأيقونة العلوية ──
        Positioned(
          top: 0,
          child: Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: gold.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isOtpSent ? Icons.sms_outlined : Icons.person_add,
                size: 55,
                color: AppColors.primary,
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
          color: isSelected ? gold.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? gold : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? deepRose : chocolate.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? chocolate : chocolate.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: chocolate.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── حقل إدخال موحد ──
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
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
              enabled: enabled && !_loading,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLength: maxLength,
              inputFormatters: digitsOnly
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: const TextStyle(
                color: chocolate,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: chocolate.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                counterText: '',
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
          if (toggle != null) toggle,
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
