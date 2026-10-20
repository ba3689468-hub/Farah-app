import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah/core/constants/app_colors.dart';

class AddEditStoreScreen extends StatefulWidget {
  final String initialType; // ✅ استقبال النوع من الشاشة السابقة

  const AddEditStoreScreen({super.key, required this.initialType});

  @override
  State<AddEditStoreScreen> createState() => _AddEditStoreScreenState();
}

class _AddEditStoreScreenState extends State<AddEditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  
  bool _loading = false;

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

    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('stores').add({
        'providerId': uid,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': widget.initialType, // ✅ نستخدم النوع الممرر
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم إنشاء المتجر بنجاح!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); 
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
        title: const Text('بيانات المتجر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عرض النوع المختار بجانب أيقونة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نوع المتجر المختار:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(widget.initialType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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

              // وصف المتجر
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
