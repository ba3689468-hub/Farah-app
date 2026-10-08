import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _phone = '';
  String? _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameCtrl.text = data['fullName'] ?? '';
          _phone = data['phone'] ?? '';
          _role = data['role'] ?? 'user';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // ✅ حفظ التعديلات
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'no user';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': _nameCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ تغيير كلمة المرور
  Future<void> _changePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw 'no user';

      // ── إعادة المصادقة ──
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassCtrl.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      // ── تغيير كلمة المرور ──
      await user.updatePassword(_newPassCtrl.text.trim());

      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تغيير كلمة المرور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ';
      if (e.code == 'wrong-password') msg = 'كلمة المرور الحالية خاطئة';
      if (e.code == 'weak-password') msg = 'كلمة المرور الجديدة ضعيفة';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text('تعديل الملف الشخصي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── الصورة الشخصية ──
              _buildAvatar(),
              const SizedBox(height: 24),

              // ── قسم المعلومات الشخصية ──
              _buildSectionTitle('المعلومات الشخصية', Icons.person_outline),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameCtrl,
                      hint: 'الاسم الكامل',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        if (v.trim().length < 3) return 'الاسم قصير';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyField(
                      value: _phone ?? 'غير محدد',
                      hint: 'رقم الهاتف',
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyField(
                      value: _role == 'provider' ? 'مزوّد خدمة' : 'زبون',
                      hint: 'نوع الحساب',
                      icon: Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── زر حفظ المعلومات ──
              _buildSaveButton(
                text: 'حفظ التعديلات',
                icon: Icons.save_outlined,
                onTap: _loading ? null : _saveProfile,
              ),

              const SizedBox(height: 30),

              // ── قسم تغيير كلمة المرور ──
              _buildSectionTitle('تغيير كلمة المرور', Icons.lock_outline),
              const SizedBox(height: 12),
              Form(
                key: _passFormKey,
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _currentPassCtrl,
                      hint: 'كلمة المرور الحالية',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(
                          () => _obscureCurrent = !_obscureCurrent),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildPasswordField(
                      controller: _newPassCtrl,
                      hint: 'كلمة المرور الجديدة',
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوبة';
                        if (v.length < 6) return 'كلمة المرور قصيرة (6+)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildPasswordField(
                      controller: _confirmPassCtrl,
                      hint: 'تأكيد كلمة المرور',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'مطلوب';
                        if (v != _newPassCtrl.text) {
                          return 'كلمة المرور غير متطابقة';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSaveButton(
                text: 'تغيير كلمة المرور',
                icon: Icons.lock_reset,
                onTap: _loading ? null : _changePassword,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── الصورة الشخصية ──
  Widget _buildAvatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 55, color: Colors.white),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt,
                  color: primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── عنوان القسم ──
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── حقل عادي ──
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: textDark.withValues(alpha: 0.5), fontSize: 14),
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
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── حقل للقراءة فقط ──
  Widget _buildReadOnlyField({
    required String value,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: textDark, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text(hint,
                      style: const TextStyle(
                          color: textLight, fontSize: 11)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(value,
                      style: const TextStyle(
                          color: textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: textLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('ثابت',
                style: TextStyle(color: textLight, fontSize: 10)),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ── حقل كلمة المرور ──
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: validator,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: textDark.withValues(alpha: 0.5), fontSize: 14),
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
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: textDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── زر الحفظ ──
  Widget _buildSaveButton({
    required String text,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
