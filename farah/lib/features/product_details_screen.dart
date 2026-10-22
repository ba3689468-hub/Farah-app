import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> productData;
  final Map<String, dynamic> storeData;

  const ProductDetailsScreen({
    super.key,
    required this.productData,
    required this.storeData,
  });

  static const Color primary = AppColors.primary;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final name = productData['name'] ?? 'منتج';
    final price = productData['price'] ?? 0;
    final description = productData['description'] ?? 'لا يوجد وصف لهذا المنتج.';
    final image = productData['image'];
    final category = productData['category'] ?? '';
    
    final storeName = storeData['name'] ?? 'متجر';
    final phone = storeData['phone'] ?? '';
    final location = storeData['location'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
              child: (image != null && image.toString().isNotEmpty)
                  ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            
            // تفاصيل المنتج
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // القسم
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // الاسم والسعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '$price د.ل',
                        style: const TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // الوصف
                  const Text('وصف المنتج:', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(color: textLight, fontSize: 14, height: 1.6)),
                  const Divider(height: 30),
                  
                  // معلومات المتجر
                  const Text('معلومات البائع:', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(storeName, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: textLight, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(location, style: const TextStyle(color: textLight, fontSize: 14))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // شريط سفلي للتواصل
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(phone, name),
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('اطلب عبر واتساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 55),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchCaller(phone),
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('اتصال مباشر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة فتح واتساب برسالة جاهزة
  Future<void> _launchWhatsApp(String phone, String productName) async {
    final message = Uri.encodeComponent('مرحباً، أنا مهتم بمنتج "$productName" في تطبيق فرح. هل هو متوفر؟');
    final url = 'https://wa.me/218${phone.startsWith('0') ? phone.substring(1) : phone}?text=$message';
    
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  // دالة الاتصال الهاتفي
  Future<void> _launchCaller(String phone) async {
    final url = 'tel:$phone';
    if (!await launchUrl(Uri.parse(url))) {
      throw 'Could not launch Phone';
    }
  }
}
