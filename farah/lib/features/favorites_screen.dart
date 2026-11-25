import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah/core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ✅ الهيدر الوردي
          _buildPinkHeader(),

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
                              hall['_id'] = halls[i].id;
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

  // ✅ دالة بناء الهيدر الوردي
  Widget _buildPinkHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
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

  Widget _buildFavoriteCard(Map<String, dynamic> hall) {
    // ... الكود الخاص ببطاقة المفضلة لديك ...
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
             Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]), child: const Icon(Icons.image, color: Colors.grey)),
             const SizedBox(width: 12),
             Expanded(child: Text(hall['name'] ?? 'قاعة', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
    );
  }
}
