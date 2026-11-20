import 'dart:io';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  bool _loading = false;
  bool _passLoading = false;
  bool _uploadingImage = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String? _existingImageUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException')) {
      return 'تعذر الاتصال بالخادم، تحقق من الإنترنت وأعد المحاولة';
    }
    return 'حدث خطأ غير متوقع، حاول مرة أخرى';
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
          _existingImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      if (mounted) _showError('تعذر تحميل البيانات: ${_friendlyError(e)}');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      setState(() {
        _pickedImage = File(pickedFile.path);
        _uploadingImage = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول';

      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl =
          Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImage': publicUrl});

      if (mounted) {
        setState(() {
          _existingImageUrl = publicUrl;
          _pickedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تحديث الصورة الشخصية بنجاح',
                  style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pickedImage = null);
        _showError('فشل رفع الصورة: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('الاسم مطلوب');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fullName': _nameCtrl.text.trim()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حفظ التعديلات بنجاح',
                  style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showError('تعذر الحفظ: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.trim().length < 6) {
      _showError('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showError('تأكيد كلمة المرور غير متطابق');
      return;
    }

    setState(() => _passLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول';

      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _currentPassCtrl.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تغيير كلمة المرور بنجاح',
                  style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.green),
        );
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } catch (e) {
      if (mounted) _showError('تأكد من كلمة المرور الحالية');
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('تعديل الملف الشخصي',
            style: TextStyle(
                fontFamily: 'Tajawal',
                color: textDark,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [primary, primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _uploadingImage
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : ClipOval(
                            child: _pickedImage != null
                                ? Image.file(_pickedImage!,
                                    fit: BoxFit.cover, width: 120, height: 120)
                                : (_existingImageUrl != null &&
                                        _existingImageUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        placeholder: (context, url) =>
                                            const Icon(Icons.person,
                                                size: 60, color: Colors.white),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.person,
                                                size: 60, color: Colors.white),
                                      )
                                    : const Icon(Icons.person,
                                        size: 60, color: Colors.white),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: const Icon(Icons.camera_alt,
                            color: primary, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _sectionTitle('المعلومات الشخصية', Icons.person_outline),
            const SizedBox(height: 16),

            _field(
                controller: _nameCtrl,
                hint: 'الاسم الكامل',
                icon: Icons.person_outline),
            const SizedBox(height: 14),

            // رقم الهاتف (ثابت)
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: primaryDark.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  _iconBox(Icons.phone_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('رقم الهاتف',
                            style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: textLight,
                                fontSize: 12)),
                        Text(
                            FirebaseAuth.instance.currentUser?.email
                                    ?.replaceAll('@farah.app', '') ??
                                'غير متوفر',
                            style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('ثابت',
                        style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: textLight,
                            fontSize: 10)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _gradientButton(
              label: 'حفظ التعديلات',
              icon: Icons.save,
              loading: _loading,
              onTap: _loading ? null : _saveProfile,
            ),

            const SizedBox(height: 30),
            Divider(color: primary.withValues(alpha: 0.15)),
            const SizedBox(height: 20),

            _sectionTitle('تغيير كلمة المرور', Icons.lock_outline),
            const SizedBox(height: 16),

            _field(
              controller: _currentPassCtrl,
              hint: 'كلمة المرور الحالية',
              icon: Icons.lock_outline,
              obscure: _hideCurrent,
              onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
            ),
            const SizedBox(height: 14),
            _field(
              controller: _newPassCtrl,
              hint: 'كلمة المرور الجديدة',
              icon: Icons.lock_reset_outlined,
              obscure: _hideNew,
              onToggle: () => setState(() => _hideNew = !_hideNew),
            ),
            const SizedBox(height: 14),
            _field(
              controller: _confirmPassCtrl,
              hint: 'تأكيد كلمة المرور',
              icon: Icons.lock_reset_outlined,
              obscure: _hideConfirm,
              onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _passLoading ? null : _changePassword,
                icon: _passLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: primary, strokeWidth: 2))
                    : const Icon(Icons.lock_open),
                label: const Text('تحديث كلمة المرور',
                    style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(icon, color: primary, size: 20),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  /// حقل موحد بنفس شكل شاشتي الدخول والتسجيل
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool? obscure,
    VoidCallback? onToggle,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: primaryDark.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const SizedBox(width: 6),
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure ?? false,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    fontFamily: 'Tajawal',
                    color: textLight.withValues(alpha: 0.8),
                    fontSize: 14),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (onToggle != null)
            IconButton(
              icon: Icon(
                  (obscure ?? false)
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: primary,
                  size: 20),
              onPressed: onToggle,
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primary, primaryDark]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(label,
                          style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
