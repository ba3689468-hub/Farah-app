import 'package:flutter/material.dart';

class ClayContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;
  final double borderRadius;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ClayContainer({
    super.key,
    required this.child,
    this.height = 100,
    this.width = 100,
    this.borderRadius = 20,
    this.color = Colors.white,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        
        // ===================================================
        // 🛑 هنا كان يوجد التوهج (الظلال). تم إزالته تماماً.
        // ===================================================
        boxShadow: [
          BoxShadow(
            color: Colors.transparent, // 1. اللون شفاف تماماً
            blurRadius: 0,             // 2. التمويه صفر (لا يوجد توهج)
            spreadRadius: 0,           // 3. الانتشار صفر
            offset: const Offset(0, 0),// 4. الإزاحة صفر
          ),
        ],
        // 💡 يمكنك حذف مصفوفة boxShadow بالكامل بدلاً من هذا الكود، 
        // وستحصل على نفس النتيجة (إزالة التوهج).
      ),
      child: child,
    );
  }
}
