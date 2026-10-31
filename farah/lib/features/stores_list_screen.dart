import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // أضفنا هذا
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'store_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
// استيراد ملفات السلة (تأكد من المسار الصحيح)
import 'package:farah/cart_provider.dart'; 
import 'package:farah/cart_screen.dart'; 

class StoresListScreen extends ConsumerStatefulWidget { // تم التعديل هنا
  final String initialCategory; 

  const StoresListScreen({super.key, this.initialCategory = 'الكل'});

  @override
  ConsumerState<StoresListScreen> createState() => _StoresListScreenState(); // تم التعديل هنا
}

class _StoresListScreenState extends ConsumerState<StoresListScreen> { // تم التعديل هنا
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;
  static const Color bgColor = Color(0xFFF9F9FB);

  late String _selectedCategory;
  
  final List<String> _categories = [
    'الكل', 
    'فساتين وأزياء', 
    'تجميل وعطور', 
    'ضيافة وحلويات', 
    'ديكور وتجهيزات', 
    'تصوير وفيديو', 
    'كوش وأعراس',
    'أحذية',
    'ملابس نسائية',
    'مجوهرات',
    'هدايا'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'الكل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('المتاجر', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontWeight: FontWeight.w800, fontSize: 20)),
        iconTheme: const IconThemeData(color: textDark),
        // --- بداية كود السلة المضاف ---
        actions: [
          Consumer( // نستخدم Consumer لكي تتحدث الأيقونة فقط دون إعادة بناء الشاشة
            builder: (context, ref, child) {
              final cartItems = ref.watch(cartProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: textDark),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (cartItems.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${cartItems.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8), // مسافة بسيطة من اليمين
        ],
        // --- نهاية كود السلة المضاف ---
      ),
      body: Column(
        children: [
          // شريط التصنيفات
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final isSelected = _selectedCategory == _categories[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = _categories[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isSelected ? primary : Colors.grey.withValues(alpha: 0.2)),
                        boxShadow: isSelected ? [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                      ),
                      child: Center(
                        child: Text(
                          _categories[i],
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: isSelected ? Colors.white : textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
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
                    : allStores.where((doc) {
                        final storeType = (doc.data() as Map)['type'] ?? '';
                        return storeType.toString().contains(_selectedCategory) || _selectedCategory.contains(storeType.toString());
                      }).toList();

                if (stores.isEmpty) {
                  return const Center(child: Text('لا توجد متاجر في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
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
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.storefront, color: primary, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store['name'] ?? 'متجر', style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(store['type'] ?? '', style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: textLight, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(store['location'] ?? '', style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, color: textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
