import 'package:flutter/material.dart';

class FarahGlassLoginScreen extends StatefulWidget {
  const FarahGlassLoginScreen({super.key});

  @override
  State<FarahGlassLoginScreen> createState() => _FarahGlassLoginScreenState();
}

class _FarahGlassLoginScreenState extends State<FarahGlassLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  static const Color gold      = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF4E5B1);
  static const Color rose      = Color(0xFFE8B4B8);
  static const Color deepRose  = Color(0xFFB76E79);
  static const Color cream     = Color(0xFFFFF8F0);
  static const Color chocolate = Color(0xFF3E2723);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB76E79), Color(0xFFD4AF37), Color(0xFFF4E5B1)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: _buildGlassCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: -20, left: 20, right: 20,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(color: deepRose.withOpacity(0.6), blurRadius: 60, spreadRadius: 10)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cream.withOpacity(0.80), rose.withOpacity(0.70)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(120),
                bottomLeft: Radius.circular(120),
                bottomRight: Radius.circular(80),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.4),
              boxShadow: [BoxShadow(color: deepRose.withOpacity(0.35), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تسجيل الدخول',
                  style: TextStyle(color: chocolate, fontSize: 30, fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.white54, blurRadius: 6, offset: Offset(0, 2))])),
                const SizedBox(height: 6),
                Container(
                  width: 60, height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gold, lightGold, gold]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                _glassField(controller: _userCtrl, hint: 'البريد الإلكتروني أو الهاتف', icon: Icons.person_outline),
                const SizedBox(height: 18),
                _glassField(
                  controller: _passCtrl, hint: '••••••••••••••', icon: Icons.lock_outline, obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: chocolate, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  SizedBox(
                    height: 22, width: 22,
                    child: Checkbox(
                      value: _remember, onChanged: (v) => setState(() => _remember = v!),
                      activeColor: deepRose, checkColor: Colors.white,
                      side: BorderSide(color: chocolate.withOpacity(0.6), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('تذكرني', style: TextStyle(color: chocolate, fontSize: 13)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('نسيت كلمة المرور؟',
                      style: TextStyle(color: deepRose, fontSize: 13, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline, decorationColor: deepRose)),
                  ),
                ]),
                const SizedBox(height: 26),
                Container(
                  width: 200, height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB76E79), Color(0xFFD4AF37), Color(0xFFF4E5B1)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: gold.withOpacity(0.55), blurRadius: 22, offset: const Offset(0, 8))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم ربط الزر بـ Firebase لاحقاً')),
                        );
                      },
                      child: const Center(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.celebration, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('دخول', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 2)),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('ليس لديك حساب؟ ', style: TextStyle(color: chocolate.withOpacity(0.75), fontSize: 13)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('أنشئ حساباً الآن',
                      style: TextStyle(color: deepRose, fontSize: 13, fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline, decorationColor: deepRose)),
                  ),
                ]),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 95, height: 95,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white,
              border: Border.all(color: gold, width: 2),
              boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 22, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4AF37), Color(0xFFB76E79)],
                ).createShader(bounds),
                child: const Icon(Icons.person, size: 55, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [BoxShadow(color: deepRose.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const SizedBox(width: 6),
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB76E79), Color(0xFFD4AF37)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: gold.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            textAlign: TextAlign.right,
            style: const TextStyle(color: chocolate, fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: chocolate.withOpacity(0.55), fontSize: 14),
              border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (suffix != null) suffix,
        const SizedBox(width: 10),
      ]),
    );
  }
}