import 'dart:ui';
import 'package:flutter/material.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  static const Color baseCream  = Color(0xFFFFF9F5);
  static const Color coralPink  = Color(0xFFFF6B9D);
  static const Color softPurple = Color(0xFFB794F6);
  static const Color skyBlue    = Color(0xFF6BCFFF);
  static const Color peach      = Color(0xFFFFB088);
  static const Color mint       = Color(0xFF7FE7C4);
  static const Color warmRed    = Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: baseCream),
        Positioned(top: -120, right: -100,
          child: _blob(coralPink, 400, 0.75)),
        Positioned(top: 80, left: -140,
          child: _blob(softPurple, 380, 0.65)),
        Positioned(top: 320, right: -160,
          child: _blob(skyBlue, 360, 0.60)),
        Positioned(bottom: 180, left: -100,
          child: _blob(peach, 340, 0.60)),
        Positioned(bottom: -140, right: -80,
          child: _blob(mint, 380, 0.55)),
        Positioned(top: 520, left: -160,
          child: _blob(warmRed, 320, 0.45)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}
