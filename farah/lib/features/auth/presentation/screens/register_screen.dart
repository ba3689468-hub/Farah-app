import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
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
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      await repo.saveUserData(UserModel(
        uid: cred.user!.uid,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: widget.role,
      ));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == 'provider' ? 'تسجيل مزوّد' : 'تسجيل زبون'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                validator: (v) => !v!.contains('@') ? 'بريد غير صالح' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) => v!.length < 6 ? '6 أحرف على الأقل' : null,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إنشاء الحساب'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
