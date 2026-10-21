import 'package:flutter/material.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'add_edit_store_screen.dart';

class SelectStoreTypeScreen extends StatelessWidget {
  const SelectStoreTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. الأقسام الرئيسية (التي تظهر في الشاشة الرئيسية)
    final List<Map<String, dynamic>> mainCategories = [
      {'name': 'فساتين', 'icon': Icons.checkroom, 'color': const Color(0xFFE91E63)},
      {'name': 'تجميل', 'icon': Icons.face_retouching_natural, 'color': const Color(0xFF9C27B0)},
      {'name': 'ضيافة', 'icon': Icons.dinner_dining, 'color': const Color(0xFFFF9800)},
      {'name': 'ديكور', 'icon': Icons.local_florist, 'color': const Color(0xFF3F51B5)},
      {'name': 'متاجر', 'icon': Icons.storefront, 'color': const Color(0xFFC2185B)}, // سيفتح قائمة أخرى
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اختر نوع المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ما هو تخصص متجرك؟',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر القسم المناسب ليظهر متجرك للزبائن في المكان الصحيح.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // شبكة الأقسام
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // عمودين
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9, // نسبة الطول للعرض
                ),
                itemCount: mainCategories.length,
                itemBuilder: (context, index) {
                  final cat = mainCategories[index];
                  return _buildCategoryCard(
                    context: context,
                    title: cat['name'],
                    icon: cat['icon'],
                    color: cat['color'],
                    onTap: () {
                      if (cat['name'] == 'متاجر') {
                        // ✅ فتح القائمة السفلية للأنواع الأخرى
                        _showMoreStoresSheet(context);
                      } else {
                        // الانتقال المباشر للإضافة
                        _navigateToAddStore(context, cat['name']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── تصميم بطاقة القسم ──
  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5), // إطار ملون خفيف
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── القائمة السفلية (Bottom Sheet) للأنواع الأخرى ──
  void _showMoreStoresSheet(BuildContext context) {
    // 2. الأقسام الأخرى التي تظهر عند الضغط على "متاجر"
    final List<Map<String, dynamic>> otherCategories = [
      {'name': 'أحذية', 'icon': Icons.directions_walk, 'color': const Color(0xFF795548)},
      {'name': 'ملابس نسائية', 'icon': Icons.woman, 'color': const Color(0xFFE91E63)},
      {'name': 'مجوهرات', 'icon': Icons.diamond, 'color': const Color(0xFFFFC107)},
      {'name': 'عطور وتجميل', 'icon': Icons.spa, 'color': const Color(0xFF9C27B0)},
      {'name': 'هدايا', 'icon': Icons.card_giftcard, 'color': const Color(0xFFF44336)},
      {'name': 'أخرى', 'icon': Icons.more_horiz, 'color': const Color(0xFF607D8B)},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مؤشر السحب
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'أنواع المتاجر الأخرى',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 20),
                
                // شبكة الأقسام الفرعية
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 أعمدة لتوفير المساحة
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: otherCategories.length,
                  itemBuilder: (context, index) {
                    final cat = otherCategories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // إغلاق القائمة السفلية
                        _navigateToAddStore(context, cat['name']); // الانتقال للإضافة
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: (cat['color'] as Color).withValues(alpha: 0.3), width: 1.5),
                              boxShadow: [BoxShadow(color: (cat['color'] as Color).withValues(alpha: 0.05), blurRadius: 10)],
                            ),
                            child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cat['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── دالة الانتقال لشاشة إضافة المتجر ──
  void _navigateToAddStore(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditStoreScreen(initialType: type),
      ),
    );
  }
}
