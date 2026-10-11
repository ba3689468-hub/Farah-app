import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء حجز جديد باستخدام Transactions لمنع الحجز المزدوج
  Future<Map<String, dynamic>> createBooking({
    required String venueId,
    required String userId,
    required String date, // بصيغة YYYY-MM-DD
    required double totalAmount,
    required double depositAmount,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // 1. تحديد مسار التوفر
        final availabilityRef = _firestore
            .collection('availability')
            .doc('${venueId}_$date');
        
        // 2. قراءة حالة التوفر
        final availabilityDoc = await transaction.get(availabilityRef);

        // 3. التحقق من أن التاريخ غير محجوز
        if (availabilityDoc.exists && availabilityDoc.data()!['status'] == 'booked') {
          throw Exception('عذراً، هذا التاريخ تم حجزه للتو. يرجى اختيار تاريخ آخر.');
        }

        // 4. تحديث حالة التوفر إلى "محجوز"
        transaction.set(availabilityRef, {
          'venueId': venueId,
          'date': date,
          'status': 'booked',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 5. إنشاء وثيقة الحجز
        final bookingRef = _firestore.collection('bookings').doc();
        transaction.set(bookingRef, {
          'bookingId': bookingRef.id,
          'userId': userId,
          'venueId': venueId,
          'date': date,
          'totalAmount': totalAmount,
          'depositAmount': depositAmount,
          'remainingAmount': totalAmount - depositAmount,
          'status': 'pending', 
          'paymentStatus': 'unpaid',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'bookingId': bookingRef.id,
          'message': 'تم إنشاء الحجز بنجاح'
        };
      });
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', '')
      };
    }
  }
}
