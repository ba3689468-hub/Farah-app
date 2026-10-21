import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'store_details_screen.dart';

class StoresListScreen extends StatefulWidget {
  const StoresListScreen({super.key});

  @override
  State<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends State<StoresListScreen> {
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  String _selectedCategory = 'الكل';
  final List<String> _categories = [
    'الكل', 'فساتين وأزياء', 'تجميل وعطور', 'ضيافة وحلويات', 'ديكور وتجهيزات', 'تصوير وفيديو', 'كوش وأعراس'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المتاجر', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط التصنيفات
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = _selectedCategory == _categories[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = _categories[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? primary : Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          color: isSelected ? Colors.white : textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // قائمة المتاجر
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stores').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }
                
                final allStores = snapshot.data?.docs ?? [];
                final stores = _selectedCategory == 'الكل' 
                    ? allStores 
                    : allStores.where((doc) => (doc.data() as Map)['type'] == _selectedCategory).toList();

                if (stores.isEmpty) {
                  return const Center(child: Text('لا توجد متاجر في هذا القسم', style: TextStyle(color: textLight)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stores.length,
                  itemBuilder: (context, i) {
                    final store = stores[i].data() as Map<String, dynamic>;
                    return _buildStoreCard(store, stores[i].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, String storeId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoreDetailsScreen(storeId: storeId, storeData: store),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.storefront, color: primary, size: 35),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store['name'] ?? 'متجر', style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(store['type'] ?? '', style: const TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: textLight, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(store['location'] ?? '', style: const TextStyle(color: textLight, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, color: textLight, size: 16),
          ],
        ),
      ),
    );
  }
}
