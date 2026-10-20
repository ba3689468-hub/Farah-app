import 'dart:io';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ تمت الإضافة

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productData;
  final String? productId;
  final String storeId; // ✅ معرف المتجر (إلزامي)

  const AddEditProductScreen({
    super.key, 
    this.productData, 
    this.productId, 
    required this.storeId, // ✅ تمت الإضافة هنا
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  String _selectedCategory = 'فساتين';
  final List<String> _categories = ['فساتين', 'تجميل', 'ضيافة', 'ديكور', 'متاجر أخرى'];

  File? _imageFile;
  String? _existingImageUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productData != null) {
      _nameCtrl.text = widget.productData!['name'] ?? '';
      _priceCtrl.text = widget.productData!['price']?.toString() ?? '';
      _descCtrl.text = widget.productData!['description'] ?? '';
      _existingImageUrl = widget.productData!['image'];
      if (_categories.contains(widget.productData!['category'])) {
        _selectedCategory = widget.productData!['category'];
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── اختيار صورة من المعرض ──
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // ── رفع الصورة إلى Supabase ──
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _existingImageUrl;
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/${FirebaseAuth.instance.currentUser!.uid}/$fileName';
      
      // استخدام نفس bucket القاعات
      await Supabase.instance.client.storage.from('venue_images').upload(path, _imageFile!);
      return Supabase.instance.client.storage.from('venue_images').getPublicUrl(path);
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // ── حفظ بيانات المنتج ──
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // رفع الصورة أولاً
    final imageUrl = await _uploadImage();

    final data = {
      'providerId': uid,
      'storeId': widget.storeId, // ✅ هنا يتم ربط المنتج بالمتجر
      'name': _nameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      'description': _descCtrl.text.trim(),
      'category': _selectedCategory,
      'image': imageUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.productId == null) {
        // إضافة جديد
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        // تعديل موجود
        await FirebaseFirestore.instance.collection('products').doc(widget.productId).update(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ المنتج بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
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
        title: Text(widget.productId == null ? 'إضافة منتج' : 'تعديل المنتج', style: const TextStyle(color: Colors.white)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── صورة المنتج ──
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16), 
                              // ✅ استخدام CachedNetworkImage
                              child: CachedNetworkImage(
                                imageUrl: _existingImageUrl!, 
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: primary)),
                                errorWidget: (context, url, error) => const Center(child: Icon(Icons.error, color: Colors.red)),
                              )
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: primary),
                                SizedBox(height: 8),
                                Text('اختر صورة للمنتج', style: TextStyle(color: primary)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),
              
              // ── اسم المنتج ──
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDecoration('اسم المنتج'),
                validator: (v) => v!.isEmpty ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 12),
              
              // ── السعر ──
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('السعر (د.ل)'),
                validator: (v) => v!.isEmpty ? 'السعر مطلوب' : null,
              ),
              const SizedBox(height: 12),
              
              // ── القسم ──
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _inputDecoration('القسم'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              
              // ── الوصف ──
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration('الوصف (اختياري)'),
              ),
              const SizedBox(height: 24),
              
              // ── زر الحفظ ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('حفظ المنتج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textLight),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
