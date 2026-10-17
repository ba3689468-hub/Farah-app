import 'package:flutter/material.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'add_edit_hall_screen.dart';
import 'add_edit_product_screen.dart';

class ProviderChoiceScreen extends StatelessWidget {
  const ProviderChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'مرحباً بك في فرح!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              const Text(
                'ماذا تود أن تضيف أولاً؟',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              
              // خيار إضافة قاعة
              _buildChoiceCard(
                context: context,
                title: 'إضافة قاعة أفراح',
                subtitle: 'لعرض قاعتك واستقبال الحجوزات',
                icon: Icons.storefront,
                color: AppColors.primary,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditHallScreen()),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true); // العودة للوحة التحكم
                  }
                },
              ),
              
              const SizedBox(height: 20),
              
              // خيار إضافة متجر
              _buildChoiceCard(
                context: context,
                title: 'إضافة متجر / خدمة',
                subtitle: 'لعرض منتجاتك (فساتين، ديكور، ضيافة...)',
                icon: Icons.shopping_bag,
                color: Colors.purple,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
                  );
                  if (result == true && context.mounted) {
                    Navigator.pop(context, true); // العودة للوحة التحكم
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
