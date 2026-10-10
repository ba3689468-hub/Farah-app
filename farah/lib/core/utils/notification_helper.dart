import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  NotificationHelper._();

  /// إرسال إشعار لمستخدم معين
  ///
  /// [userId] معرف المستخدم المستهدف
  /// [title] عنوان الإشعار
  /// [body] محتوى الإشعار
  /// [type] نوع الإشعار: booking, confirmed, cancelled, review, payment
  /// [data] بيانات إضافية (مثل hallId, bookingId)
  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (userId.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // نتجاهل الأخطاء بدلاً من إيقاف العملية الرئيسية
      // print('Notification error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // دوال جاهزة للاستخدام في التطبيق
  // ═══════════════════════════════════════════

  /// إشعار للمزود عند حجز جديد
  static Future<void> notifyProviderNewBooking({
    required String providerId,
    required String hallName,
    required String customerName,
    required String bookingId,
  }) async {
    await send(
      userId: providerId,
      title: '🎉 حجز جديد!',
      body: '$customerName حجز قاعة "$hallName". راجع التفاصيل للتأكيد.',
      type: 'booking',
      data: {'bookingId': bookingId},
    );
  }

  /// إشعار للزبون عند تأكيد الحجز
  static Future<void> notifyCustomerConfirmed({
    required String customerId,
    required String hallName,
    required String bookingId,
  }) async {
    await send(
      userId: customerId,
      title: '✅ تم تأكيد حجزك',
      body: 'تم تأكيد حجزك في "$hallName". نتمنى لك مناسبة سعيدة!',
      type: 'confirmed',
      data: {'bookingId': bookingId},
    );
  }

  /// إشعار للزبون عند رفض الحجز
  static Future<void> notifyCustomerCancelled({
    required String customerId,
    required String hallName,
    required String bookingId,
    bool isByProvider = true,
  }) async {
    await send(
      userId: customerId,
      title: '❌ تم رفض الحجز',
      body: isByProvider
          ? 'نأسف، تم رفض حجزك في "$hallName" من قِبل المزود.'
          : 'تم إلغاء حجزك في "$hallName" بنجاح.',
      type: 'cancelled',
      data: {'bookingId': bookingId},
    );
  }

  /// إشعار للمزود عند إضافة تقييم جديد
  static Future<void> notifyProviderNewReview({
    required String providerId,
    required String hallName,
    required String customerName,
    required int rating,
  }) async {
    final stars = '⭐' * rating;
    await send(
      userId: providerId,
      title: '⭐ تقييم جديد',
      body: '$customerName قيّم "$hallName" بـ $stars',
      type: 'review',
      data: {'rating': rating},
    );
  }
}
