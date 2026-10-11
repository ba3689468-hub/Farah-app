import 'dart:io';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddEditHallScreen extends StatefulWidget {
  final Map<String, dynamic>? hallData;
  final String? hallId;
  const AddEditHallScreen({super.key, this.hallData, this.hallId});

  @override
  State<AddEditHallScreen> createState() => _AddEditHallScreenState();
}

class _AddEditHallScreenState extends State<AddEditHallScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _customAmenityCtrl = TextEditingController();

  String _selectedCity = 'طرابلس';
  final List<String> _selectedAmenities = [];
  bool _loading = false;
  bool _uploadingImage = false;

  File? _pickedImage;
  String _existingImageUrl = '';

  final ImagePicker _picker = ImagePicker();

  static const String _hallType = 'قاعات أفراح';

  final List<String> _cities = const [
    'طرابلس',
    'بنغازي',
    'مصراتة',
    'الزاوية',
    'سبها',
  ];

  final List<String> _amenitiesList = const [
    'تكييف',
    'مواقف سيارات',
    'إضاءة متطورة',
    'كوشة',
    'خدمة ضيافة',
    'نظام صوتي',
    'شاشة عرض',
    'مطبخ',
  ];

  bool get _isEdit => widget.hallId != null && widget.hallData != null;

  List<String> get _customAmenities =>
      _selectedAmenities.where((a) => !_amenitiesList.contains(a)).toList();

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final data = widget.hallData!;
      _nameCtrl.text = data['name'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _priceCtrl.text = (data['price'] ?? '').toString();
      _capacityCtrl.text = (data['capacity'] ?? '').toString();
      _phoneCtrl.text = data['providerPhone'] ?? data['phone'] ?? '';
      _existingImageUrl = data['image'] ?? data['coverImage'] ?? '';
      _selectedCity = _cities.contains(data['city']) ? data['city'] : 'طرابلس';
      if (data['amenities'] is List) {
        _selectedAmenities.addAll(
          List<String>.from(data['amenities']),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _phoneCtrl.dispose();
    _customAmenityCtrl.dispose();
    super.dispose();
  }

  // ✅ اختيار صورة من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage = File(picked.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الصورة: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ✅ رفع الصورة إلى Supabase Storage
  Future<String> _uploadImageToSupabase(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    final fileName =
        '${user?.uid ?? "unknown"}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final supabase = Supabase.instance.client;

    await supabase.storage.from('halls').upload(
          fileName,
          image,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage.from('halls').getPublicUrl(fileName);
    return publicUrl;
  }

  void _addCustomAmenity() {
    final text = _customAmenityCtrl.text.trim();
    if (text.isEmpty) return;
    if (_selectedAmenities.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا المرفق مضاف مسبقاً'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    setState(() {
      _selectedAmenities.add(text);
      _customAmenityCtrl.clear();
    });
  }

  Future<void> _save() async {
    // ✅ إضافة تلقائية لأي نص متبقٍ في حقل المرافق المخصصة
    final pendingText = _customAmenityCtrl.text.trim();
    if (pendingText.isNotEmpty) {
      if (!_selectedAmenities.contains(pendingText)) {
        _selectedAmenities.add(pendingText);
      }
      _customAmenityCtrl.clear();
    }

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ── التحقق من وجود صورة ──
    if (_pickedImage == null && _existingImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار صورة للقاعة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ رفع الصورة إذا كانت جديدة
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        setState(() => _uploadingImage = true);
        imageUrl = await _uploadImageToSupabase(_pickedImage!);
        setState(() => _uploadingImage = false);
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'city': _selectedCity,
        'type': _hallType,
        'image': imageUrl,
        'coverImage': imageUrl,
        'providerPhone': _phoneCtrl.text.trim(),
        'amenities': _selectedAmenities,
        'providerId': user.uid,
        'isAvailable': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('halls')
            .doc(widget.hallId)
            .update(data);
      } else {
        data['rating'] = 0.0;
        data['reviewsCount'] = 0;
        data['bookingsCount'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('halls').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? '✅ تم تحديث القاعة بنجاح'
                : '✅ تم إضافة القاعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) {
        setState(() {
          _loading = false;
          _uploadingImage = false;
        });
      }
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
        title: Text(
          _isEdit ? 'تعديل القاعة' : 'إضافة قاعة جديدة',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── المعلومات الأساسية ──
                _sectionTitle('المعلومات الأساسية', Icons.info_outline),
                const SizedBox(height: 12),
                _buildField(
                  controller: _nameCtrl,
                  hint: 'اسم القاعة',
                  icon: Icons.celebration_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    if (v.trim().length < 3) return 'الاسم قصير';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _descCtrl,
                  hint: 'وصف القاعة',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الوصف مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── التفاصيل ──
                _sectionTitle('التفاصيل', Icons.tune),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceCtrl,
                        hint: 'السعر (د.ل)',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        controller: _capacityCtrl,
                        hint: 'السعة',
                        icon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'مطلوب';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── المدينة ──
                _dropdownTitle('المدينة', Icons.location_city),
                const SizedBox(height: 8),
                _buildChips(
                  items: _cities,
                  selected: _selectedCity,
                  onSelect: (v) => setState(() => _selectedCity = v),
                ),
                const SizedBox(height: 24),

                // ── الصورة ──
                _sectionTitle('صورة القاعة', Icons.image_outlined),
                const SizedBox(height: 6),
                const Text(
                  'اختر صورة واضحة من معرض هاتفك',
                  style: TextStyle(color: textLight, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _buildImagePicker(),
                const SizedBox(height: 24),

                // ── رقم الهاتف ──
                _sectionTitle('معلومات التواصل', Icons.phone_outlined),
                const SizedBox(height: 12),
                _buildField(
                  controller: _phoneCtrl,
                  hint: 'رقم هاتف المزود',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  digitsOnly: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    if (v.trim().length < 9) return 'الرقم قصير';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── المرافق ──
                _sectionTitle('المرافق والخدمات', Icons.room_service_outlined),
                const SizedBox(height: 6),
                const Text(
                  'اختر من القائمة أو أضف مرفقاً جديداً بنفسك',
                  style: TextStyle(color: textLight, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenitiesList.map((a) {
                    final selected = _selectedAmenities.contains(a);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _selectedAmenities.remove(a);
                        } else {
                          _selectedAmenities.add(a);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? primary
                                : Colors.black.withValues(alpha: 0.1),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: selected ? primary : textLight,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              a,
                              style: TextStyle(
                                color: selected ? primary : textDark,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_customAmenities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      const Text('مرافق مخصصة',
                          style: TextStyle(
                              color: textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customAmenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a,
                              style: const TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() {
                                _selectedAmenities.remove(a);
                              }),
                              child: const Icon(Icons.close,
                                  color: primary, size: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.2),
                              width: 1),
                        ),
                        child: TextField(
                          controller: _customAmenityCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              color: textDark, fontSize: 13),
                          onSubmitted: (_) => _addCustomAmenity(),
                          decoration: const InputDecoration(
                            hintText: 'أضف مرفقاً أو خدمة مخصصة...',
                            hintStyle: TextStyle(
                                color: textLight, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addCustomAmenity,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [primary, primaryDark]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ── زر الحفظ ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _uploadingImage
                                    ? 'جاري رفع الصورة...'
                                    : 'جاري الحفظ...',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  _isEdit
                                      ? Icons.save_outlined
                                      : Icons.add_circle_outline,
                                  size: 22),
                              const SizedBox(width: 10),
                              Text(
                                _isEdit
                                    ? 'حفظ التعديلات'
                                    : 'إضافة القاعة',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_pickedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.file(
                _pickedImage!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (_existingImageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                _existingImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: primary.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: textLight, size: 40),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary.withValues(alpha: 0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: primary.withValues(alpha: 0.6), size: 50),
                const SizedBox(height: 10),
                const Text('لا توجد صورة',
                    style: TextStyle(color: textLight, fontSize: 13)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _pickImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: primary.withValues(alpha: 0.3), width: 1.5),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text(
              _pickedImage == null && _existingImageUrl.isEmpty
                  ? 'اختر صورة من المعرض'
                  : 'تغيير الصورة',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
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
        Text(title,
            style: const TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _dropdownTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 18),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChips({
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final active = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [primary, primaryDark])
                  : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: active ? Colors.white : textDark,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool digitsOnly = false,
    int maxLines = 1,
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
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 6),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
              enabled: !_loading,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              inputFormatters: digitsOnly
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: textDark.withValues(alpha: 0.45),
                    fontSize: 13),
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
}
