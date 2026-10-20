import 'package:flutter/material.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'add_edit_hall_screen.dart';
import 'select_store_type_screen.dart'; // ✅ تم استيراد شاشة اختيار نوع المتجر

class ProviderChoiceScreen extends StatelessWidget {
  const ProviderChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اختر نوع نشاطك', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'مرحباً بك في فرح! 🎉',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'ماذا تريد أن تضيف اليوم؟ يمكنك إضافة قاعة أفراح أو إنشاء متجر لمنتجاتك وخدماتك.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),

            // خيار إضافة قاعة
            _buildChoiceCard(
              context: context,
              title: 'إضافة قاعة أفراح',
              subtitle: 'أضف قاعتك، حدد أسعارها وفتراتها المتاحة',
              icon: Icons.storefront,
              color: AppColors.primary,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditHallScreen()),
                );
                // إذا تمت الإضافة بنجاح، اخرج من هذه الشاشة واذهب للوحة التحكم
                if (result == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 20),

            // خيار إضافة متجر (تم إصلاحه هنا)
            _buildChoiceCard(
              context: context,
              title: 'إنشاء متجر',
              subtitle: 'فساتين، ضيافة، تجميل، ديكور... أضف منتجاتك الآن',
              icon: Icons.local_mall,
              color: Colors.blue,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  // ✅ التعديل هنا: الانتقال لشاشة اختيار النوع بدلاً من إضافة المنتج مباشرة
                  MaterialPageRoute(builder: (_) => const SelectStoreTypeScreen()),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
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
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
