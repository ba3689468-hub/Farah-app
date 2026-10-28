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
  
  // ── المتحكمات النصية ──
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weekendPriceCtrl = TextEditingController();
  final _holidayPriceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController(); // ✅ رابط الخريطة
  final _customAmenityCtrl = TextEditingController();

  String _selectedCity = 'طرابلس';
  final List<String> _selectedAmenities = [];
  
  // ✅ قائمة الخدمات الإضافية (الاسم + السعر)
  final List<Map<String, dynamic>> _additionalServices = [];
  
  bool _loading = false;
  bool _uploadingMedia = false;

  // ✅ المتغيرات الخاصة بالصور والفيديو المتعدد
  final List<File> _pickedImages = [];
  final List<String> _existingImages = [];
  File? _pickedVideo;
  String _existingVideoUrl = '';

  final ImagePicker _picker = ImagePicker();
  static const String _hallType = 'قاعات أفراح';

  final List<String> _cities = const [
    'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'سبها',
  ];

  final List<String> _amenitiesList = const [
    'تكييف', 'مواقف سيارات', 'إضاءة متطورة', 'كوشة', 'خدمة ضيافة', 'نظام صوتي', 'شاشة عرض', 'مطبخ',
  ];

  bool get _isEdit => widget.hallId != null && widget.hallData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final data = widget.hallData!;
      _nameCtrl.text = data['name'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _priceCtrl.text = (data['price'] ?? '').toString();
      _weekendPriceCtrl.text = (data['weekendPrice'] ?? '').toString() != '0' ? (data['weekendPrice'] ?? '').toString() : '';
      _holidayPriceCtrl.text = (data['holidayPrice'] ?? '').toString() != '0' ? (data['holidayPrice'] ?? '').toString() : '';
      _capacityCtrl.text = (data['capacity'] ?? '').toString();
      _phoneCtrl.text = data['providerPhone'] ?? data['phone'] ?? '';
      _mapUrlCtrl.text = data['mapUrl'] ?? '';
      _selectedCity = _cities.contains(data['city']) ? data['city'] : 'طرابلس';
      
      // جلب الصور المتعددة القديمة
      if (data['images'] is List && (data['images'] as List).isNotEmpty) {
        _existingImages.addAll(List<String>.from(data['images']));
      } else if (data['image'] != null && data['image'].toString().isNotEmpty) {
        _existingImages.add(data['image']);
      }
      
      // جلب الفيديو القديم
      _existingVideoUrl = data['videoUrl'] ?? '';

      // جلب المرافق
      if (data['amenities'] is List) {
        _selectedAmenities.addAll(List<String>.from(data['amenities']));
      }
      
      // جلب الخدمات الإضافية القديمة
      if (data['additionalServices'] is List) {
        for (var s in data['additionalServices']) {
          _additionalServices.add({
            'name': s['name'], 
            'price': s['price'].toString()
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _weekendPriceCtrl.dispose();
    _holidayPriceCtrl.dispose();
    _capacityCtrl.dispose();
    _phoneCtrl.dispose();
    _mapUrlCtrl.dispose();
    _customAmenityCtrl.dispose();
    super.dispose();
  }

  // ── 1. اختيار صور متعددة ──
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70, 
        maxWidth: 1200
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_pickedImages.length < 10) { 
              _pickedImages.add(File(file.path));
            }
          }
        });
      }
    } catch (e) {
      _showError('تعذر اختيار الصور: $e');
    }
  }

  // ── 2. اختيار فيديو ──
  Future<void> _pickVideo() async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery, 
        maxDuration: const Duration(minutes: 1)
      );
      
      if (picked != null) {
        setState(() {
          _pickedVideo = File(picked.path);
        });
      }
    } catch (e) {
      _showError('تعذر اختيار الفيديو: $e');
    }
  }

  // ── 3. رفع الصور إلى Supabase ──
  Future<List<String>> _uploadImages() async {
    List<String> urls = List.from(_existingImages);
    final user = FirebaseAuth.instance.currentUser;
    final supabase = Supabase.instance.client;

    for (var image in _pickedImages) {
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg';
      final path = '${user?.uid}/$fileName';
      
      await supabase.storage.from('halls').upload(path, image);
      urls.add(supabase.storage.from('halls').getPublicUrl(path));
    }
    
    return urls;
  }

  // ── 4. رفع الفيديو إلى Supabase ──
  Future<String> _uploadVideo() async {
    if (_pickedVideo == null) return _existingVideoUrl;
    
    final user = FirebaseAuth.instance.currentUser;
    final supabase = Supabase.instance.client;
    
    final fileName = 'vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = '${user?.uid}/$fileName';
    
    await supabase.storage.from('halls').upload(
      path, 
      _pickedVideo!, 
      fileOptions: const FileOptions(contentType: 'video/mp4')
    );
    
    return supabase.storage.from('halls').getPublicUrl(path);
  }

  // ── 5. إضافة مرفق مخصص ──
  void _addCustomAmenity() {
    final text = _customAmenityCtrl.text.trim();
    if (text.isEmpty) return;
    
    if (!_selectedAmenities.contains(text)) {
      setState(() {
        _selectedAmenities.add(text);
        _customAmenityCtrl.clear();
      });
    }
  }

  // ── 6. إضافة صف لخدمة إضافية ──
  void _addServiceRow() {
    setState(() {
      _additionalServices.add({'name': '', 'price': ''});
    });
  }

  // ── 7. حفظ البيانات في Firebase ──
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_pickedImages.isEmpty && _existingImages.isEmpty) {
      _showError('الرجاء اختيار صورة واحدة على الأقل');
      return;
    }

    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _uploadingMedia = true);
      
      final imageUrls = await _uploadImages();
      final videoUrl = await _uploadVideo();
      
      setState(() => _uploadingMedia = false);

      // تجهيز قائمة الخدمات الإضافية
      final servicesToSave = _additionalServices
          .where((s) => s['name'].toString().isNotEmpty && s['price'].toString().isNotEmpty)
          .map((s) => {
            'name': s['name'], 
            'price': double.tryParse(s['price'].toString()) ?? 0.0
          })
          .toList();

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'weekendPrice': int.tryParse(_weekendPriceCtrl.text.trim()) ?? 0,
        'holidayPrice': int.tryParse(_holidayPriceCtrl.text.trim()) ?? 0,
        'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'city': _selectedCity,
        'type': _hallType,
        
        // الحقول الجديدة
        'image': imageUrls.isNotEmpty ? imageUrls[0] : '', // الصورة الأساسية
        'images': imageUrls, // قائمة كل الصور
        'videoUrl': videoUrl, // رابط الفيديو
        'mapUrl': _mapUrlCtrl.text.trim(), // رابط الخريطة
        'additionalServices': servicesToSave, // الخدمات الإضافية
        
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
        _showSuccess(_isEdit ? 'تم تحديث القاعة بنجاح' : 'تم إضافة القاعة بنجاح');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('خطأ: $e');
    } finally {
      if (mounted) {
        setState(() { 
          _loading = false; 
          _uploadingMedia = false; 
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
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textDark,
          ),
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
                  validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _descCtrl,
                  hint: 'وصف القاعة',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'الوصف مطلوب' : null,
                ),
                const SizedBox(height: 24),

                // ── التفاصيل والأسعار ──
                _sectionTitle('التفاصيل والأسعار', Icons.tune),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _priceCtrl,
                        hint: 'السعر الأساسي',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
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
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _weekendPriceCtrl,
                        hint: 'سعر الخميس والجمعة',
                        icon: Icons.weekend,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        controller: _holidayPriceCtrl,
                        hint: 'سعر المواسم',
                        icon: Icons.celebration,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _phoneCtrl,
                  hint: 'رقم هاتف المزود',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                
                // ✅ رابط الخريطة
                _buildField(
                  controller: _mapUrlCtrl,
                  hint: 'رابط الموقع على Google Maps (اختياري)',
                  icon: Icons.map_outlined,
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

                // ── الصور والفيديو ──
                _sectionTitle('صور وفيديو القاعة', Icons.perm_media_outlined),
                const SizedBox(height: 6),
                const Text(
                  'يمكنك إضافة حتى 10 صور وفيديو قصير',
                  style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _buildMediaPicker(),
                const SizedBox(height: 24),

                // ── المرافق ──
                _sectionTitle('المرافق والخدمات', Icons.room_service_outlined),
                const SizedBox(height: 12),
                _buildAmenitiesSection(),
                
                const SizedBox(height: 24),

                // ── الخدمات الإضافية ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('خدمات إضافية (بأسعار)', Icons.add_box_outlined),
                    IconButton(
                      onPressed: _addServiceRow,
                      icon: const Icon(Icons.add_circle, color: primary, size: 28),
                    ),
                  ],
                ),
                ..._additionalServices.asMap().entries.map((entry) {
                  int idx = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: entry.value['name'],
                            decoration: const InputDecoration(
                              hintText: 'اسم الخدمة',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) => _additionalServices[idx]['name'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: entry.value['price'],
                            decoration: const InputDecoration(
                              hintText: 'السعر',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _additionalServices[idx]['price'] = val,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _additionalServices.removeAt(idx)),
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 40),

                // ── زر الحفظ ──
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                              const SizedBox(width: 12),
                              Text(
                                _uploadingMedia ? 'جاري رفع الوسائط...' : 'جاري الحفظ...',
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            _isEdit ? 'حفظ التعديلات' : 'إضافة القاعة',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold),
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

  // ═══════════════════════════════════════════════════════════
  // 🖼️ دوال واجهة الوسائط (صور وفيديو)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMediaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._existingImages.map((url) => _mediaThumb(url: url, isVideo: false)),
            ..._pickedImages.map((file) => _mediaThumb(file: file, isVideo: false)),
            if (_existingVideoUrl.isNotEmpty && _pickedVideo == null) 
              _mediaThumb(url: _existingVideoUrl, isVideo: true),
            if (_pickedVideo != null) 
              _mediaThumb(file: _pickedVideo!, isVideo: true),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickImages,
                icon: const Icon(Icons.photo_library, color: primary),
                label: const Text('إضافة صور', style: TextStyle(fontFamily: 'Tajawal', color: primary)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: primary.withValues(alpha: 0.3))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _pickVideo,
                icon: const Icon(Icons.video_library, color: primary),
                label: const Text('إضافة فيديو', style: TextStyle(fontFamily: 'Tajawal', color: primary)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: primary.withValues(alpha: 0.3))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mediaThumb({String? url, File? file, required bool isVideo}) {
    return Container(
      width: 80, 
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), 
        color: Colors.grey.shade200
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? Container(
                    color: Colors.black54, 
                    child: const Center(child: Icon(Icons.play_circle_fill, size: 40, color: Colors.white))
                  )
                : (file != null 
                    ? Image.file(file, fit: BoxFit.cover) 
                    : Image.network(url!, fit: BoxFit.cover)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🛠️ دوال واجهة المرافق
  // ═══════════════════════════════════════════════════════════
  Widget _buildAmenitiesSection() {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amenitiesList.map((a) {
            final selected = _selectedAmenities.contains(a);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) { _selectedAmenities.remove(a); } else { _selectedAmenities.add(a); }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? primary.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? primary : Colors.black.withValues(alpha: 0.1), 
                    width: selected ? 1.5 : 1
                  ),
                ),
                child: Text(
                  a, 
                  style: TextStyle(
                    fontFamily: 'Tajawal', 
                    color: selected ? primary : textDark, 
                    fontSize: 12, 
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500
                  )
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(14), 
                  border: Border.all(color: primary.withValues(alpha: 0.2), width: 1)
                ),
                child: TextField(
                  controller: _customAmenityCtrl,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13),
                  onSubmitted: (_) => _addCustomAmenity(),
                  decoration: const InputDecoration(
                    hintText: 'أضف مرفقاً مخصصاً...', 
                    hintStyle: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12), 
                    border: InputBorder.none, 
                    isDense: true, 
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)
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
                  gradient: const LinearGradient(colors: [primary, primaryDark]), 
                  borderRadius: BorderRadius.circular(14)
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 دوال مساعدة (Titles, Fields, Chips)
  // ═══════════════════════════════════════════════════════════
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), 
          child: Icon(icon, color: primary, size: 18)
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _dropdownTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 18),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChips({
    required List<String> items, 
    required String selected, 
    required Function(String) onSelect
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? Colors.transparent : primary.withValues(alpha: 0.15)),
            ),
            child: Text(
              item, 
              style: TextStyle(
                fontFamily: 'Tajawal', 
                color: active ? Colors.white : textDark, 
                fontSize: 12, 
                fontWeight: active ? FontWeight.bold : FontWeight.w600
              )
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
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 6),
          Container(
            width: 42, 
            height: 42,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]), 
              borderRadius: BorderRadius.circular(12)
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
              inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
              style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontFamily: 'Tajawal', color: textDark.withValues(alpha: 0.45), fontSize: 13),
                errorStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontSize: 11, height: 0.8),
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
  
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')), 
      backgroundColor: Colors.redAccent
    )
  );
  
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')), 
      backgroundColor: Colors.green
    )
  );
}
