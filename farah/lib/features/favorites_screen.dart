import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../hall_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  // ✅ استخدام Stream بدلاً من Future للتحديث الفوري
  Stream<List<Map<String, dynamic>>> _favoritesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final data = userDoc.data();
      final List<String> favIds = List<String>.from(data?['favorites'] ?? []);

      if (favIds.isEmpty) return <Map<String, dynamic>>[];

      final halls = <Map<String, dynamic>>[];
      for (final id in favIds) {
        if (id.isEmpty) continue;
        final hallDoc =
            await FirebaseFirestore.instance.collection('halls').doc(id).get();
        if (hallDoc.exists) {
          final d = hallDoc.data()!;
          d['_id'] = hallDoc.id;
          halls.add(d);
        }
      }
      return halls;
    });
  }

  Future<void> _removeFavorite(String hallId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'favorites': FieldValue.arrayRemove([hallId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الإزالة من المفضلة'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── العنوان ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'المفضلة',
                    style: TextStyle(
                        color: textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite,
                        color: Colors.redAccent, size: 20),
                  ),
                ],
              ),
            ),
            // ── قائمة المفضلة ──
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _favoritesStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: primary));
                  }

                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 60, color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text('حدث خطأ: ${snap.error}',
                              style: const TextStyle(
                                  color: textDark, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  final halls = snap.data ?? [];

                  if (halls.isEmpty) {
                    return _buildEmpty();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: halls.length,
                    itemBuilder: (context, i) {
                      return _buildFavoriteCard(halls[i]);
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

  // ── لا يوجد مفضلة ──
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border,
                size: 70, color: primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد قاعات في المفضلة',
            style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على ♡ في أي قاعة لحفظها هنا',
            style: TextStyle(color: textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── بطاقة القاعة ──
  Widget _buildFavoriteCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];
    final id = hall['_id'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(20)),
              child: SizedBox(
                height: 120,
                width: 120,
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.celebration,
                              color: Colors.white, size: 40),
                        ),
                      )
                    : Container(
                        color: primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.celebration,
                            color: Colors.white, size: 40),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(city,
                          style: const TextStyle(
                              color: textLight, fontSize: 12)),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on_outlined,
                          color: textLight, size: 14),
                    ]),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('$price د.ل',
                          style: const TextStyle(
                              color: primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeFavorite(id),
              icon: const Icon(Icons.favorite,
                  color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
