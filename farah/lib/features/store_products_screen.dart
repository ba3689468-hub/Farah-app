import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_edit_product_screen.dart';

class StoreProductsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreProductsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('منتجات ${widget.storeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditProductScreen(storeId: widget.storeId)),
              );
              if (result == true) setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('storeId', isEqualTo: widget.storeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد منتجات في هذا المتجر', style: TextStyle(fontSize: 16, color: textLight)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditProductScreen(storeId: widget.storeId)),
                      );
                      if (result == true) setState(() {});
                    },
                    child: const Text('إضافة منتج جديد'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              return _buildProductCard(product, products[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String docId) {
    final name = product['name'] ?? 'منتج';
    final price = product['price'] ?? 0;
    final image = product['image'];
    final category = product['category'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: SizedBox(
              width: 100,
              height: 100,
              child: (image != null && image.toString().isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: image, 
                      fit: BoxFit.cover, 
                      errorWidget: (_, __, ___) => Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.image, color: primary))
                    )
                  : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.image, color: primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(category, style: const TextStyle(color: primary, fontSize: 10)),
                ),
                const SizedBox(height: 8),
                Text('$price د.ل', style: const TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddEditProductScreen(
                      storeId: widget.storeId,
                      productData: product, 
                      productId: docId
                    )),
                  );
                  if (result == true) setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteProduct(docId),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف المنتج', style: TextStyle(color: textDark)),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنتج'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
