import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'store_management_screen.dart'; // لإدارة المتاجر
import 'select_store_type_screen.dart'; // لإضافة متجر جديد
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';
import 'notifications_screen.dart';
import 'auth/presentation/screens/login_screen_farah.dart';

class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});
  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildStoreHome(),
            const StoreManagementScreen(), // شاشة إدارة المنتجات
            const _StoreProfileScreen(), // حسابي
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStoreHome() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      slivers: [
        // الشريط العلوي
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primary, primaryDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_mall, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('لوحة المتجر', style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStoreTypeScreen()));
                    setState(() {}); // تحديث عند العودة
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.add, color: primary, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),

        // إحصائيات المتاجر
        SliverToBoxAdapter(
          child: FutureBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('stores').where('providerId', isEqualTo: uid).snapshots(),
            builder: (context, storeSnap) {
              final storeCount = storeSnap.data?.docs.length ?? 0;
              
              return FutureBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('providerId', isEqualTo: uid).snapshots(),
                builder: (context, productSnap) {
                  final productCount = productSnap.data?.docs.length ?? 0;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _statCard(Icons.store, 'المتاجر', '$storeCount', Colors.blue),
                        const SizedBox(width: 12),
                        _statCard(Icons.shopping_bag, 'المنتجات', '$productCount', Colors.purple),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // إجراءات سريعة
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, primaryDark]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إدارة متجرك بسهولة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('أضف منتجاتك، وعدل بيانات متجرك لتجذب المزيد من الزبائن.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text('إدارة المتاجر والمنتجات'),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.dashboard_outlined, 'active': Icons.dashboard, 'label': 'الرئيسية'},
      {'icon': Icons.shopping_bag_outlined, 'active': Icons.shopping_bag, 'label': 'منتجاتي'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'حسابي'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final active = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: active ? 16 : 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                    color: active ? Colors.white : textLight,
                    size: 20,
                  ),
                  if (active) ...[
                    const SizedBox(width: 6),
                    Text(items[i]['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── حسابي الخاص بصاحب المتجر ──
class _StoreProfileScreen extends StatelessWidget {
  const _StoreProfileScreen();

  @override
  Widget build(BuildContext context) {
    // نفس كود حسابي الخاص بالمزود (يمكنك استخدام الكود القديم)
    // ...
    return const Center(child: Text('حسابي'));
  }
}
