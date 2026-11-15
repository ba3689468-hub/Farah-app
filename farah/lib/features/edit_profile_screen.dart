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

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameCtrl.text = data['fullName'] ?? '';
          _existingImageUrl = data['profileImage']; // تأكد من اسم الحقل في Firebase
        });
      }
    } catch (e) {
      _showError('خطأ في تحميل البيانات: $e');
    }
  }

  // ✅ دالة اختيار ورفع الصورة
  Future<void> _pickAndUploadImage() async {
    // 1. رسالة تأكيد أن الزر يعمل
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري فتح المعرض...', style: TextStyle(fontFamily: 'Tajawal'))),
      );
    }

    final picker = ImagePicker();
    try {
      // 2. فتح المعرض
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (pickedFile == null) {
        // إذا اختار المستخدم الإلغاء
        return;
      }

      setState(() {
        _pickedImage = File(pickedFile.path);
        _uploadingImage = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول';

      // 3. الرفع إلى Supabase
      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName'; // تأكد أن Bucket اسمه avatars

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));
          
      final publicUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);

      // 4. تحديث رابط الصورة في Firebase
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImage': publicUrl,
      });

      if (mounted) {
        setState(() {
          _existingImageUrl = publicUrl;
          _pickedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح!', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pickedImage = null);
        _showError('فشل رفع الصورة: $e');
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

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullName': _nameCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('خطأ في الحفظ: $e');
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

      final cred = EmailAuthProvider.credential(email: user.email!, password: _currentPassCtrl.text.trim());
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassCtrl.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green),
        );
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } catch (e) {
      _showError('خطأ: تأكد من كلمة المرور الحالية');
    } finally {
      if (mounted) setState(() => _passLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ صورة الملف الشخصي
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [primary, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: _uploadingImage
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ClipOval(
                            child: _pickedImage != null
                                ? Image.file(_pickedImage!, fit: BoxFit.cover, width: 120, height: 120)
                                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        width: 120, height: 120,
                                        placeholder: (context, url) => const Icon(Icons.person, size: 60, color: Colors.white),
                                        errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.white),
                                      )
                                    : const Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                  ),
                  
                  // ✅ زر الكاميرا
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: const Icon(Icons.camera_alt, color: primary, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // المعلومات الشخصية
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('المعلومات الشخصية', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.person_outline, color: primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(controller: _nameCtrl, hint: 'الاسم الكامل', icon: Icons.person_outline),
            const SizedBox(height: 12),
            
            // رقم الهاتف (ثابت)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.phone_outlined, color: primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('رقم الهاتف', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                        Text(FirebaseAuth.instance.currentUser?.email?.replaceAll('@farah.app', '') ?? 'غير متوفر', style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ثابت', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 10)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _saveProfile,
                icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                label: const Text('حفظ التعديلات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // تغيير كلمة المرور
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.lock_outline, color: primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildPassField(controller: _currentPassCtrl, hint: 'كلمة المرور الحالية', icon: Icons.lock_outline),
            const SizedBox(height: 12),
            _buildPassField(controller: _newPassCtrl, hint: 'كلمة المرور الجديدة', icon: Icons.lock_reset),
            const SizedBox(height: 12),
            _buildPassField(controller: _confirmPassCtrl, hint: 'تأكيد كلمة المرور', icon: Icons.lock_reset),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _passLoading ? null : _changePassword,
                icon: _passLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primary, strokeWidth: 2)) : const Icon(Icons.lock_open),
                label: const Text('تحديث كلمة المرور', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: primary.withValues(alpha: 0.3))),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Tajawal', color: textLight),
          border: InputBorder.none,
          icon: Icon(icon, color: primary),
        ),
      ),
    );
  }

  Widget _buildPassField({required TextEditingController controller, required String hint, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: TextField(
        controller: controller,
        obscureText: true,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Tajawal', color: textLight),
          border: InputBorder.none,
          icon: Icon(icon, color: primary),
        ),
      ),
    );
  }
}
