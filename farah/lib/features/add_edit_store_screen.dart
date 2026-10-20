import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah/core/constants/app_colors.dart';

class AddEditStoreScreen extends StatefulWidget {
  const AddEditStoreScreen({super.key});

  @override
  State<AddEditStoreScreen> createState() => _AddEditStoreScreenState();
}

class _AddEditStoreScreenState extends State<AddEditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  
  String? _selectedType;
  bool _loading = false;

  // أنواع المتاجر المتاحة
  final List<String> _storeTypes = [
    'ملابس وأزياء',
    'تجميل وعطور',
    'ضيافة وحلويات',
    'ديكور وتجهيزات',
    'تصوير وفيديو',
    'أخرى',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار نوع المتجر'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('stores').add({
        'providerId': uid,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': _selectedType,
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء المتجر بنجاح!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // العودة للوحة التحكم وتحديثها
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة متجر جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة توضيحية صغيرة
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront, size: 60, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 30),

              // اسم المتجر
              const Text('اسم المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: متجر لمسة فنان',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) => v!.isEmpty ? 'الرجاء إدخال اسم المتجر' : null,
              ),
              const SizedBox(height: 20),

              // وصف المتجر (الصفة)
              const Text('وصف المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'اكتب نبذة عن المتجر، الخدمات التي يقدمها...',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v!.isEmpty ? 'الرجاء إدخال وصف المتجر' : null,
              ),
              const SizedBox(height: 20),

              // نوع المتجر
              const Text('نوع المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  hintText: 'اختر نوع المتجر',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _storeTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              const SizedBox(height: 20),

              // رقم التواصل
              const Text('رقم التواصل (واتساب / هاتف)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '09X XXXXXXX',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => v!.isEmpty ? 'الرجاء إدخال رقم التواصل' : null,
              ),
              const SizedBox(height: 20),

              // الموقع
              const Text('الموقع / العنوان', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثال: طرابلس - شارع الجمهورية',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v!.isEmpty ? 'الرجاء إدخال الموقع' : null,
              ),
              const SizedBox(height: 40),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveStore,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ المتجر'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
