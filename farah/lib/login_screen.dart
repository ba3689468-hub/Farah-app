import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/screens/role_select_screen.dart';
import 'hall_list_screen.dart';
import 'core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HallListScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _error = 'لا يوجد حساب بهذا البريد.';
        } else if (e.code == 'wrong-password') {
          _error = 'كلمة المرور غير صحيحة.';
        } else if (e.code == 'invalid-email') {
          _error = 'البريد الإلكتروني غير صالح.';
        } else {
          _error = 'حدث خطأ: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _error = 'حدث خطأ غير متوقع.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.celebration,
                size: 90, color: AppColors.goldPrimary),
            const SizedBox(height: 20),
            Text(
              'مرحباً بك في فرح',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.goldPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('دخول'),
            ),
            const SizedBox(height: 15),

            // ⭐ زر الانتقال لإنشاء حساب جديد
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectScreen()),
                );
              },
              child: const Text(
                'ليس لديك حساب؟ سجّل الآن',
                style: TextStyle(color: AppColors.goldPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
