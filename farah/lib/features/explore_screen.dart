import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';
import '../hall_details_screen.dart'; 
import '../core/widgets/shimmer_loading.dart'; 
// ⚠️ هام: قم بتفعيل استيراد شاشة المنتج/المتجر الخاصة بك هنا (عدل المسار حسب مشروعك)
import 'package:farah/features/product_details_screen.dart'; 

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  // تغيير نوع الـ Future ليجلب قائمة مختلطة
  late Future<List<Map<String, dynamic>>> _exploreDataFuture;
  
  String _selectedCategory = 'الكل';
  // التصنيفات الجديدة
  final List<String> _categories = ['الكل', 'قاعات أفراح', 'متاجر'];

  @override
  void initState() {
    super.initState();
    _fetchExploreData();
  }

  // دالة الجلب والخلط الجديدة
  void _fetchExploreData() {
    setState(() {
      _exploreDataFuture = _getMixedData();
    });
  }

  Future<List<Map<String, dynamic>>> _getMixedData() async {
    List<Map<String, dynamic>> mixedList = [];

    try {
      // 1. جلب القاعات
      final hallsSnapshot = await FirebaseFirestore.instance.collection('halls').get();
      for (var doc in hallsSnapshot.docs) {
        var data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'hall'; // علامة للتمييز
        mixedList.add(data);
      }

      // 2. جلب المتاجر/المنتجات 
      // ⚠️ تنبيه: تأكد من اسم المجموعة في Firebase (هل هي 'stores' أم 'products'؟)
      final storesSnapshot = await FirebaseFirestore.instance.collection('stores').get(); 
      for (var doc in storesSnapshot.docs) {
        var data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'store'; // علامة للتمييز
        mixedList.add(data);
      }

      // 3. خلط البيانات عشوائياً
      mixedList.shuffle();
      
      return mixedList;
    } catch (e) {
      throw Exception('حدث خطأ في جلب البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'استكشف',
          style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontWeight: FontWeight.w900, fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          // شريط التصنيفات
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final isSelected = _selectedCategory == _categories[i];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = _categories[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: isSelected ? [
                        BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                      ] : [],
                      border: Border.all(color: isSelected ? primary : Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: isSelected ? Colors.white : textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // قائمة العرض
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _exploreDataFuture,
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
                        Text('${snapshot.error}', style: const TextStyle(fontFamily: 'Tajawal')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchExploreData,
                          child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Tajawal')),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined, size: 80, color: primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text('لا توجد بيانات لعرضها', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                // فلترة البيانات حسب التصنيف المختار
                List<Map<String, dynamic>> displayData = snapshot.data!;
                if (_selectedCategory == 'قاعات أفراح') {
                  displayData = displayData.where((item) => item['_type'] == 'hall').toList();
                } else if (_selectedCategory == 'متاجر') {
                  displayData = displayData.where((item) => item['_type'] == 'store').toList();
                }

                if (displayData.isEmpty) {
                   return const Center(child: Text('لا يوجد شيء في هذا القسم', style: TextStyle(fontFamily: 'Tajawal')));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 5),
                  itemCount: displayData.length,
                  itemBuilder: (context, i) {
                    return _buildModernCard(displayData[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // التصميم العصري الجديد للبطاقة
  Widget _buildModernCard(Map<String, dynamic> item) {
    final isHall = item['_type'] == 'hall';
    final name = item['name'] ?? (isHall ? 'قاعة' : 'متجر');
    final city = item['city'] ?? item['location'] ?? 'غير محدد'; // دعم حقل الموقع للاثنين
    final price = item['price'] ?? 0;
    final rating = double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0;
    final image = item['image'] ?? item['coverImage'];

    return GestureDetector(
      onTap: () {
        if (isHall) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: item)),
          );
        } else {
          // الانتقال لشاشة تفاصيل المنتج
          // ⚠️ قد تحتاج لتعديل المتغيرات الممررة بناءً على شاشة المنتج الخاصة بك
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                productData: item, 
                storeData: item, // نمرر نفس البيانات هنا مؤقتاً حتى لا يحدث خطأ
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 240, // ارتفاع البطاقة الجديد
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. الصورة
              Positioned.fill(
                child: (image != null && image.toString().isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: image.toString(), 
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                      )
                    : Container(
                        color: primary.withValues(alpha: 0.1), 
                        child: Icon(isHall ? Icons.celebration : Icons.store, color: primary, size: 60)
                      ),
              ),
              
              // 2. تدرج لوني لأسفل الصورة
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.85)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. شارة (قاعة / متجر)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHall ? primary : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHall ? 'قاعة' : 'متجر',
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 4. النصوص
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // الموقع
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(city, style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        // السعر والتقييم
                        Row(
                          children: [
                            if (rating > 0) ...[
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              '$price د.ل',
                              style: const TextStyle(fontFamily: 'Tajawal', color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
