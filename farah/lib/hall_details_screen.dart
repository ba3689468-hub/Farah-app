import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'booking_screen.dart';

class HallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  final String? hallId;
  const HallDetailsScreen({super.key, required this.hallData, this.hallId});

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  static const Color primary = AppColors.primary;
  static const Color darkRed = AppColors.primaryDark;
  static const Color cream = AppColors.background;
  static const Color chocolate = AppColors.textPrimary;

  final _pageCtrl = PageController();
  int _currentImage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hall = widget.hallData;
    final name = hall['name'] ?? 'صالة بدون اسم';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final description = hall['description'] ?? 'لا يوجد وصف متاح.';
    final capacity = hall['capacity'] ?? 0;
    final images = _getImages(hall);

    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: chocolate, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border,
                      color: chocolate, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قريباً: المفضلة')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(images),
            ),
          ),
          SliverToBoxAdapter(
              child: _buildInfoSection(
                  name, city, price, rating, capacity, description)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBookingBar(price),
    );
  }

  List<String> _getImages(Map<String, dynamic> hall) {
    final gallery = hall['gallery'];
    if (gallery is List && gallery.isNotEmpty) {
      return List<String>.from(gallery);
    }
    final single = hall['image'] ?? hall['coverImage'];
    if (single != null) return [single.toString()];
    return [];
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: primary.withValues(alpha: 0.3),
        child: Center(
          child: Icon(Icons.celebration,
              size: 80, color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageCtrl,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentImage = i),
          itemBuilder: (context, i) => Image.network(
            images[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: primary.withValues(alpha: 0.3),
              child: Center(
                child: Icon(Icons.celebration,
                    size: 80, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
        // تدرج سفلي
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
        // نقاط التنقل
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _currentImage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        // شارة التقييم
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  (widget.hallData['rating'] ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                      color: chocolate,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String name, String city, int price, double rating,
      int capacity, String description) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: chocolate, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: primary, size: 18),
              const SizedBox(width: 4),
              Text(city,
                  style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoChip(Icons.star, rating.toStringAsFixed(1), 'التقييم'),
              const SizedBox(width: 12),
              _infoChip(Icons.people_outline, '$capacity', 'السعة'),
              const SizedBox(width: 12),
              _infoChip(Icons.attach_money, '$price', 'د.ل/ليلة'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('الوصف',
              style: TextStyle(
                  color: chocolate, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 14, height: 1.7)),
          const SizedBox(height: 24),
          const Text('المرافق والخدمات',
              style: TextStyle(
                  color: chocolate, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _amenityChip('تكييف'),
              _amenityChip('مواقف سيارات'),
              _amenityChip('مسرح'),
              _amenityChip('إضاءة متطورة'),
              _amenityChip('كوشة'),
              _amenityChip('خدمة ضيافة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: chocolate,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _amenityChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: primary, size: 14),
          const SizedBox(width: 5),
          Text(name, style: const TextStyle(color: chocolate, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBookingBar(int price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('السعر يبدأ من',
                    style: TextStyle(color: Colors.black45, fontSize: 11)),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: '$price ',
                        style: const TextStyle(
                            color: primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const TextSpan(
                        text: 'د.ل',
                        style: TextStyle(color: chocolate, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      hallData: widget.hallData,
                      hallId: widget.hallId,
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, darkRed]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: const Text('احجز الآن',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
