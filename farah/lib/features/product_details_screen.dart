import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // أضفنا هذا
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';

// استيراد ملف السلة (تأكد من المسار الصحيح، إذا كان الملف في مجلد features أضف features/ قبل اسم الملف)
import 'package:farah/cart_provider.dart'; 

class ProductDetailsScreen extends ConsumerWidget { // تم التعديل هنا
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
  Widget build(BuildContext context, WidgetRef ref) { // أضفنا ref هنا
    final name = productData['name'] ?? 'منتج';
    final price = productData['price'] ?? 0;
    final description = productData['description'] ?? 'لا يوجد وصف لهذا المنتج.';
    final image = productData['image'];
    final category = productData['category'] ?? '';
    
    final storeName = storeData['name'] ?? 'متجر';
    final phone = storeData['phone'] ?? '';
    final location = storeData['location'] ?? '';

    // تحويل السعر إلى رقم لاستخدامه في السلة
    final double priceValue = double.tryParse(price.toString()) ?? 0.0;
    // محاولة جلب معرف المنتج، إذا لم يوجد نستخدم الاسم
    final String productId = productData['id'] ?? name; 

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المنتج', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // أيقونة السلة في شاشة المنتج أيضاً
          Consumer(
            builder: (context, ref, child) {
              final cartItems = ref.watch(cartProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      // نحتاج لاستيراد cart_screen.dart أيضاً
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
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
        ],
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
      
      // شريط سفلي للتواصل وإضافة السلة
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // لكي يأخذ حجم المحتوى فقط
            children: [
              // --- زر إضافة للسلة الجديد ---
              ElevatedButton.icon(
                onPressed: () {
                  // إضافة المنتج للسلة
                  ref.read(cartProvider.notifier).addToCart(
                    CartItem(
                      id: productId,
                      name: name,
                      price: priceValue,
                    ),
                  );
                  
                  // إظهار رسالة تأكيد
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة المنتج إلى السلة بنجاح!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, size: 20),
                label: const Text('أضف إلى السلة', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // لون مميز لزر السلة
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55), // يمتد بعرض الشاشة
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12), // مسافة بين الزر والصف السفلي
              // -----------------------------
              
              Row(
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
