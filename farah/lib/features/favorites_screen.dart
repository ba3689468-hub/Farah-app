import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';
import '../hall_details_screen.dart'; // تم تصحيح المسار

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
  
  // اللون القرمزي الموحد مثل صفحة المتاجر والحجوزات
  static const Color rubyRed = Color(0xFFC2185B);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // ضبط لون أيقونات شريط الحالة العلوي
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ✅ الهيدر القرمزي الموحد
          _buildRubyHeader(),

          Expanded(
            child: user == null
                ? _buildEmptyState('يجب تسجيل الدخول لعرض المفضلة')
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primary));
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final favIds = List<String>.from(data?['favorites'] ?? []);

                      if (favIds.isEmpty) {
                        return _buildEmptyState('لا توجد قاعات في المفضلة');
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('halls').where(FieldPath.documentId, whereIn: favIds).snapshots(),
                        builder: (context, hallSnap) {
                          if (!hallSnap.hasData) return const Center(child: CircularProgressIndicator(color: primary));
                          
                          final halls = hallSnap.data!.docs;
                          if (halls.isEmpty) return _buildEmptyState('لم يتم العثور على القاعات');

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: halls.length,
                            itemBuilder: (context, i) {
                              final hall = halls[i].data() as Map<String, dynamic>;
                              hall['_id'] = halls[i].id; // إضافة ID للبيانات
                              return _buildFavoriteCard(hall);
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة بناء الهيدر القرمزي الموحد
  Widget _buildRubyHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
      decoration: const BoxDecoration(
        color: rubyRed,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 42), // مساحة فارغة
          const Spacer(),
          const Text('المفضلة', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          // زر زخرفي (قلب) لتوازن التصميم
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ✅ البطاقة الجديدة والمكتملة
  Widget _buildFavoriteCard(Map<String, dynamic> hall) {
    // جلب البيانات مع وضع قيم افتراضية في حال عدم وجودها
    final name = hall['name'] ?? 'قاعة بدون اسم';
    final address = hall['address'] ?? hall['location'] ?? 'طرابلس'; // جرب حقل العنوان أو الموقع
    final price = hall['price'] ?? hall['pricePerNight'] ?? 0;
    
    // محاولة جلب الصورة من الحقول المحتملة
    String? imageUrl = hall['image'] ?? hall['hallImage'];
    if (imageUrl == null && hall['images'] is List && (hall['images'] as List).isNotEmpty) {
      imageUrl = hall['images'][0];
    }

    return GestureDetector(
      onTap: () {
        // الانتقال لصفحة التفاصيل عند الضغط
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HallDetailsScreen(hallId: hall['_id']), // تأكد من اسم كلاس صفحة التفاصيل
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.08), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Row(
          children: [
            // الصورة
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
              child: SizedBox(
                width: 110, 
                height: 110,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Container(
                        color: primary.withValues(alpha: 0.1), 
                        child: const Icon(Icons.image, color: primary, size: 40)
                      ),
              ),
            ),
            
            // المعلومات
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address, 
                            style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (price != 0)
                      Text(
                        '$price د.ل', 
                        style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
            
            // سهم للدلالة على إمكانية الضغط
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
