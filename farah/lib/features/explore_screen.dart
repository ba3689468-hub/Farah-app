import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';
import '../hall_details_screen.dart';
import '../core/widgets/shimmer_loading.dart';
import 'package:farah/features/product_details_screen.dart';
import 'package:farah/features/store_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String initialFilter;

  const ExploreScreen({super.key, this.initialFilter = 'الكل'});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color bgColor = Color(0xFFF7F3F8);

  late Future<List<Map<String, dynamic>>> _exploreDataFuture;

  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'قاعات أفراح', 'متاجر'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter;
    _fetchExploreData();
  }

  void _fetchExploreData() {
    setState(() {
      _exploreDataFuture = _getMixedData();
    });
  }

  Future<List<Map<String, dynamic>>> _getMixedData() async {
    List<Map<String, dynamic>> mixedList = [];
    try {
      final hallsSnapshot =
          await FirebaseFirestore.instance.collection('halls').get();
      for (var doc in hallsSnapshot.docs) {
        var data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'hall';
        mixedList.add(data);
      }

      final storesSnapshot =
          await FirebaseFirestore.instance.collection('stores').get();
      for (var doc in storesSnapshot.docs) {
        var data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'store';
        mixedList.add(data);
      }

      mixedList.shuffle();
      return mixedList;
    } catch (e) {
      throw Exception('حدث خطأ في جلب البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'استكشف',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final isSelected = _selectedCategory == _categories[i];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = _categories[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [primary, primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE8D5E8),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Text(
                      _categories[i],
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF9A7AAA),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text('${snapshot.error}',
                            style: const TextStyle(fontFamily: 'Tajawal')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchExploreData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Tajawal')),
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
                        Icon(Icons.storefront_outlined,
                            size: 80, color: primary.withOpacity(0.25)),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بيانات لعرضها',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Color(0xFF1A1A2E),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<Map<String, dynamic>> displayData = snapshot.data!;
                if (_selectedCategory == 'قاعات أفراح') {
                  displayData = displayData
                      .where((item) => item['_type'] == 'hall')
                      .toList();
                } else if (_selectedCategory == 'متاجر') {
                  displayData = displayData
                      .where((item) => item['_type'] == 'store')
                      .toList();
                }

                if (displayData.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا يوجد شيء في هذا القسم',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 14, right: 14, bottom: 100, top: 4),
                  itemCount: displayData.length,
                  itemBuilder: (context, i) => _buildCard(displayData[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isHall = item['_type'] == 'hall';
    final name = item['name'] ?? (isHall ? 'قاعة' : 'متجر');
    final city = item['city'] ?? item['location'] ?? 'غير محدد';
    final price = item['price'] ?? 0;
    final rating =
        double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0;
    final image = item['image'] ?? item['coverImage'];
    final isFeatured = item['featured'] ?? true;

    return GestureDetector(
      onTap: () {
        if (isHall) {
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => HallDetailsScreen(hallData: item)));
        } else {
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => StoreDetailsScreen(storeData: item)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB478B4).withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (image != null && image.toString().isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: image.toString(),
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildPlaceholder(isHall),
                            errorWidget: (_, __, ___) =>
                                _buildPlaceholder(isHall),
                          )
                        : _buildPlaceholder(isHall),

                    if (isFeatured)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primary, primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'مميزة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite_border,
                            color: primary, size: 18),
                      ),
                    ),

                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: isHall
                          ? _buildPriceBadge('$price د.ل')
                          : _buildBrowseBadge(),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: primary, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        city,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: Color(0xFFA08AB0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on_outlined,
                          color: Color(0xFFA08AB0), size: 15),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isHall) {
    return Container(
      color: isHall
          ? const Color(0xFFF0E6F0)
          : const Color(0xFFF4F0FB),
      child: Center(
        child: Icon(
          isHall ? Icons.business : Icons.shopping_bag_outlined,
          size: 60,
          color: isHall
              ? primary.withOpacity(0.25)
              : const Color(0xFF9C6BBF).withOpacity(0.25),
        ),
      ),
    );
  }

  Widget _buildPriceBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBrowseBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE8D5E8),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'تصفح المنتجات',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Color(0xFF9A7AAA),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.local_offer_outlined,
              color: Color(0xFF9A7AAA), size: 13),
        ],
      ),
    );
  }
}
