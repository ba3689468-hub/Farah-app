import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreDetailsScreen extends StatelessWidget {
  final String storeId;
  final Map<String, dynamic> storeData;

  const StoreDetailsScreen({super.key, required this.storeId, required this.storeData});

  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final storeName = storeData['name'] ?? 'متجر';
    final phone = storeData['phone'] ?? '';
    final description = storeData['description'] ?? 'لا يوجد وصف';
    final location = storeData['location'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(storeName), centerTitle: true),
      body: Column(
        children: [
          // بطاقة معلومات المتجر
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: primary),
                    const SizedBox(width: 8),
                    const Text('عن المتجر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(description, style: const TextStyle(color: textLight, height: 1.5)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(phone),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('تواصل واتساب'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchCaller(phone),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('اتصال'),
                        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // عنوان المنتجات
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('المنتجات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            ),
          ),

          // شبكة المنتجات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: storeId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primary));
                }
                
                final products = snapshot.data?.docs ?? [];
                if (products.isEmpty) {
                  return const Center(child: Text('لا توجد منتجات في هذا المتجر حالياً', style: TextStyle(color: textLight)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final product = products[i].data() as Map<String, dynamic>;
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'منتج';
    final price = product['price'] ?? 0;
    final image = product['image'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 120, width: double.infinity,
              child: (image != null && image.toString().isNotEmpty)
                  ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)
                  : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.image, color: primary, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('$price د.ل', style: const TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final url = 'https://wa.me/218${phone.startsWith('0') ? phone.substring(1) : phone}';
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  Future<void> _launchCaller(String phone) async {
    final url = 'tel:$phone';
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch Phone';
    }
  }
}
