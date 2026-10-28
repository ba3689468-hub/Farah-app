import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'hall_details_screen.dart';
import 'core/widgets/shimmer_loading.dart'; // تأكد من المسار الصحيح

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  // ✅ تعريف المتغير هنا
  late Future<QuerySnapshot> _hallsFuture;
  
  String _selectedCategory = 'الكل';
  final List<String> _categories = [
    'الكل', 'قاعات أفراح', 'قاعات مؤتمرات', 'قاعات صغيرة', 'استراحات'
  ];

  @override
  void initState() {
    super.initState();
    // ✅ الحل: تهيئة المتغير هنا لمنع خطأ LateInitializationError
    _fetchHalls();
  }

  void _fetchHalls() {
    setState(() {
      _hallsFuture = FirebaseFirestore.instance
          .collection('halls')
          // .where('type', isEqualTo: _selectedCategory) // يمكنك تفعيل هذا الفلتر لاحقاً
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'استكشف',
          style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // شريط التصنيفات
          Container(
            color: Colors.white,
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final isSelected = _selectedCategory == _categories[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = _categories[i]);
                    _fetchHalls(); // إعادة الجلب عند تغيير التصنيف
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? primary : Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: isSelected ? Colors.white : textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // قائمة القاعات
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _hallsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoading();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(fontFamily: 'Tajawal')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchHalls,
                          child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 80, color: primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('لا توجد قاعات في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final halls = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: halls.length,
                  itemBuilder: (context, i) {
                    final hall = halls[i].data() as Map<String, dynamic>;
                    hall['_id'] = halls[i].id;
                    return _buildExploreCard(hall);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            // الصورة
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              child: SizedBox(
                width: 120,
                height: 120,
                child: (image != null && image.toString().isNotEmpty)
                    ? CachedNetworkImage(imageUrl: image.toString(), fit: BoxFit.cover)
                    : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.celebration, color: primary, size: 40)),
              ),
            ),
            const SizedBox(width: 16),
            // التفاصيل
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: textLight, size: 14),
                        const SizedBox(width: 4),
                        Text(city, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$price د.ل',
                          style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
