import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'booking_screen.dart';
import 'features/add_review_screen.dart';

class HallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  final String? hallId;
  const HallDetailsScreen({super.key, required this.hallData, this.hallId});

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _pageCtrl = PageController();
  int _currentImage = 0;
  late Map<String, dynamic> _hall;

  @override
  void initState() {
    super.initState();
    _hall = Map<String, dynamic>.from(widget.hallData);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _hallId =>
      widget.hallId ?? _hall['_id'] ?? _hall['id'] ?? '';

  @override
  Widget build(BuildContext context) {
    final name = _hall['name'] ?? 'صالة بدون اسم';
    final city = _hall['city'] ?? 'غير محدد';
    final price = _hall['price'] ?? 0;
    final rating = (_hall['rating'] ?? 0).toDouble();
    final description = _hall['description'] ?? 'لا يوجد وصف متاح.';
    final capacity = _hall['capacity'] ?? 0;
    final images = _getImages(_hall);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: textDark, size: 20),
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
                  child: const Icon(Icons.share_outlined,
                      color: textDark, size: 20),
                ),
                onPressed: _shareHall,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(images),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildInfoSection(
                name, city, price, rating, capacity, description),
          ),
          SliverToBoxAdapter(child: _buildReviewsSection()),
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
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    primaryDark.withValues(alpha: 0.6),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
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
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  (_hall['rating'] ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_currentImage + 1}/${images.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('مميزة',
                    style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: primary, size: 18),
              const SizedBox(width: 4),
              Text(city,
                  style: const TextStyle(
                      color: textLight, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoCard(Icons.star, rating.toStringAsFixed(1), 'التقييم',
                  Colors.amber),
              const SizedBox(width: 10),
              _infoCard(Icons.people_outline, '$capacity', 'السعة',
                  primary),
              const SizedBox(width: 10),
              _infoCard(Icons.attach_money, '$price', 'د.ل/ليلة',
                  primaryDark),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.description_outlined,
                  color: primary, size: 20),
              SizedBox(width: 6),
              Text('الوصف',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
                color: textDark, fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.room_service_outlined,
                  color: primary, size: 20),
              SizedBox(width: 6),
              Text('المرافق والخدمات',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // ✅ عرض المرافق من البيانات الفعلية
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildAmenitiesFromData(),
          ),
        ],
      ),
    );
  }

  // ✅ بناء شرائح المرافق من بيانات القاعة الفعلية
  List<Widget> _buildAmenitiesFromData() {
    final amenities = _hall['amenities'];

    // إذا كانت قائمة فارغة أو غير موجودة
    if (amenities == null || amenities is! List || amenities.isEmpty) {
      return [
        const Text(
          'لم يتم إضافة مرافق',
          style: TextStyle(color: textLight, fontSize: 13),
        ),
      ];
    }

    // بناء شريحة لكل مرفق
    return amenities
        .map<Widget>((a) => _amenityChip(a.toString()))
        .toList();
  }

  Widget _infoCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: textLight, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amenityChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: primary, size: 14),
          const SizedBox(width: 5),
          Text(name,
              style: const TextStyle(
                  color: textDark, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reviews_outlined,
                  color: primary, size: 20),
              const SizedBox(width: 6),
              const Text('التقييمات والمراجعات',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _openAddReview,
                icon: const Icon(Icons.add, color: primary, size: 18),
                label: const Text('أضف تقييم',
                    style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      (_hall['rating'] ?? 0).toStringAsFixed(1),
                      style: const TextStyle(
                          color: primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final rating =
                            (_hall['rating'] ?? 0).toDouble();
                        return Icon(
                          i < rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_hall['reviewsCount'] ?? 0} مراجعة',
                      style: const TextStyle(
                          color: textLight, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ratingBar(5, _calcRatingPercent(5)),
                    _ratingBar(4, _calcRatingPercent(4)),
                    _ratingBar(3, _calcRatingPercent(3)),
                    _ratingBar(2, _calcRatingPercent(2)),
                    _ratingBar(1, _calcRatingPercent(1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('hallId', isEqualTo: _hallId)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child:
                        CircularProgressIndicator(color: primary),
                  ),
                );
              }

              final reviews = snap.data?.docs ?? [];

              if (reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: textLight, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'لا توجد مراجعات بعد. كن أول من يشارك تجربته!',
                          style: TextStyle(
                              color: textLight, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final sortedReviews =
                  List<QueryDocumentSnapshot>.from(reviews);
              sortedReviews.sort((a, b) {
                final aT =
                    (a.data() as Map)['createdAt'] as Timestamp?;
                final bT =
                    (b.data() as Map)['createdAt'] as Timestamp?;
                if (aT == null && bT == null) return 0;
                if (aT == null) return 1;
                if (bT == null) return -1;
                return bT.compareTo(aT);
              });

              return Column(
                children: sortedReviews
                    .map((doc) => _buildReviewItem(
                        doc.data() as Map<String, dynamic>))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAddReview() async {
    if (_hallId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن إضافة تقييم: معرف القاعة غير موجود'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          hallId: _hallId,
          hallName: _hall['name'] ?? '',
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('halls')
            .doc(_hallId)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _hall = Map<String, dynamic>.from(doc.data()!);
            _hall['_id'] = doc.id;
          });
        }
      } catch (_) {}
    }
  }

  double _calcRatingPercent(int stars) {
    final breakdown = _hall['ratingBreakdown'];
    if (breakdown is Map) {
      final count = (breakdown['$stars'] ?? 0).toDouble();
      final total = (_hall['reviewsCount'] ?? 0).toDouble();
      if (total == 0) return 0;
      return (count / total).clamp(0.0, 1.0);
    }
    return 0;
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = review['userName'] ?? 'مستخدم';
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';
    final createdAt = review['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().year}/${createdAt.toDate().month}/${createdAt.toDate().day}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [primary, primaryDark]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0] : 'م',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          color: textLight, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                  color: textDark, fontSize: 13, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingBar(int stars, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$stars',
              style: const TextStyle(
                  color: textLight, fontSize: 11),
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor:
                    Colors.black.withValues(alpha: 0.05),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              '${(percent * 100).toInt()}%',
              style: const TextStyle(
                  color: textLight, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
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
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
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
                    style: TextStyle(
                        color: textLight, fontSize: 11)),
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
                        style: TextStyle(
                            color: textDark, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _callProvider,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.phone_outlined,
                    color: primary, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      hallData: _hall,
                      hallId: _hallId,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('احجز الآن',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callProvider() async {
    final phone = _hall['providerPhone'] ??
        _hall['phone'] ??
        _hall['contactPhone'] ??
        '';

    if (phone.toString().trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد رقم هاتف متاح للمزود'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    String cleanPhone =
        phone.toString().replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('00')) {
      cleanPhone = cleanPhone.substring(2);
    }
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+218${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('218')) {
        cleanPhone = '+$cleanPhone';
      } else {
        cleanPhone = '+218$cleanPhone';
      }
    }

    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر فتح الاتصال: $cleanPhone'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareHall() async {
    final name = _hall['name'] ?? 'قاعة';
    final city = _hall['city'] ?? '';
    final price = _hall['price'] ?? 0;
    final rating = (_hall['rating'] ?? 0).toStringAsFixed(1);

    final text = '🎉 اكتشف $name على تطبيق فرح!\n\n'
        '📍 المدينة: $city\n'
        '💰 السعر: $price د.ل\n'
        '⭐ التقييم: $rating\n\n'
        '📱 حمّل تطبيق فرح من هنا:\n'
        'https://github.com/ba3689468-hub/Farah-app/releases';

    try {
      await Share.share(
        text,
        subject: 'قاعة $name على تطبيق فرح',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر المشاركة: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
