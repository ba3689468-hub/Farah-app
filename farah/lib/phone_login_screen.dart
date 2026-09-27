import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hall_list_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendCode() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HallListScreen()));
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() { _isLoading = false; _errorMessage = 'فشل الإرسال: ${e.message}'; });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() { _isLoading = false; _verificationId = verificationId; });
      },
      codeAutoRetrievalTimeout: (String verificationId) { _verificationId = verificationId; },
    );
  }

  Future<void> _verifyCode() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HallListScreen()));
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'رمز التحقق غير صحيح.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول برقم الهاتف'), backgroundColor: Colors.pinkAccent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف (مع رمز الدولة)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            if (_verificationId != null) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رمز التحقق (OTP)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
            ],
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: _isLoading ? null : (_verificationId == null ? _sendCode : _verifyCode),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_verificationId == null ? 'إرسال الرمز' : 'تأكيد الدخول', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
