import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'add_edit_store_screen.dart';
import 'store_products_screen.dart'; // ✅ شاشة المنتجات التابعة للمتجر

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المتاجر', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // ✅ فتح شاشة إضافة متجر جديد
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditStoreScreen(initialType: 'متجر عام')),
              );
              if (result == true) setState(() {});
            },
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('يجب تسجيل الدخول'))
          : StreamBuilder<QuerySnapshot>(
              // ✅ البحث في مجموعة المتاجر (stores)
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .where('providerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ في تحميل البيانات'));
                }

                final stores = snapshot.data?.docs ?? [];

                if (stores.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index].data() as Map<String, dynamic>;
                    return _buildStoreCard(store, stores[index].id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined, size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا يوجد متجر مسجل', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أنشئ متجرك الأول لتتمكن من إضافة المنتجات', style: TextStyle(color: textLight, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditStoreScreen(initialType: 'متجر عام')),
                );
                if (result == true) setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('إنشاء متجر جديد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, String storeId) {
    final name = store['name'] ?? 'متجر';
    final type = store['type'] ?? '';
    final location = store['location'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront, color: primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(type, style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: textLight, size: 12),
                          const SizedBox(width: 4),
                          Expanded(child: Text(location, style: const TextStyle(color: textLight, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // ✅ الانتقال إلى شاشة منتجات هذا المتجر
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreProductsScreen(
                            storeId: storeId,
                            storeName: name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, color: primary, size: 18),
                          SizedBox(width: 6),
                          Text('إدارة المنتجات', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
