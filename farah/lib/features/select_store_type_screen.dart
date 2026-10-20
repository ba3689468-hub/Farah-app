import 'package:flutter/material.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'add_edit_store_screen.dart';

class SelectStoreTypeScreen extends StatelessWidget {
  const SelectStoreTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة أنواع المتاجر مع الأيقونات والألوان
    final List<Map<String, dynamic>> storeTypes = [
      {'name': 'فساتين وأزياء', 'icon': Icons.checkroom, 'color': const Color(0xFFE91E63)},
      {'name': 'تجميل وعطور', 'icon': Icons.face_retouching_natural, 'color': const Color(0xFF9C27B0)},
      {'name': 'ضيافة وحلويات', 'icon': Icons.cake, 'color': const Color(0xFFFF9800)},
      {'name': 'ديكور وتجهيزات', 'icon': Icons.chair, 'color': const Color(0xFF3F51B5)},
      {'name': 'تصوير وفيديو', 'icon': Icons.camera_alt, 'color': const Color(0xFF009688)},
      {'name': 'كوش وأعراس', 'icon': Icons.auto_awesome, 'color': const Color(0xFFD4AF37)},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اختر نوع المتجر', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ما هو تخصص متجرك؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'اختر النوع المناسب ليظهر متجرك للزبائن في القسم الصحيح.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: storeTypes.length,
                itemBuilder: (context, index) {
                  final type = storeTypes[index];
                  final color = type['color'] as Color;
                  
                  return GestureDetector(
                    onTap: () {
                      // الانتقال لشاشة إضافة المتجر مع تمرير النوع المختار
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditStoreScreen(
                            initialType: type['name'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(type['icon'] as IconData, color: color, size: 36),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            type['name'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
