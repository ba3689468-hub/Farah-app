const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ═══════════════════════════════════════════════════════════
// 1. دالة تُنفذ عند دفع رسم الحجز (60 دينار)
// ═══════════════════════════════════════════════════════════
exports.onCommissionPaid = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    if (previousValue.paymentStatus === "commission_paid" || newValue.paymentStatus !== "commission_paid") {
      return null;
    }

    const bookingId = context.params.bookingId;
    const providerId = newValue.providerId;
    const userId = newValue.userId;

    try {
      const FIXED_COMMISSION = 60.0;

      await admin.firestore().collection("admin_commissions").add({
        bookingId: bookingId,
        providerId: providerId,
        totalAmount: newValue.totalAmount || 0,
        commissionAmount: FIXED_COMMISSION,
        status: "paid",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const expiresAt = admin.firestore.Timestamp.fromMillis(
        Date.now() + (48 * 60 * 60 * 1000)
      );

      await change.after.ref.update({
        status: "pending_attendance",
        commissionPaidAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: expiresAt,
        refundEligibleUntil: expiresAt,
      });

      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userToken = userDoc.data()?.fcmToken;
      if (userToken) {
        await admin.messaging().send({
          token: userToken,
          notification: {
            title: "تم تأكيد حجزك المبدئي! 🎉",
            body: "لديك 48 ساعة للتوجه للقاعة ودفع العربون.",
          },
        });
      }

      const providerDoc = await admin.firestore().collection("users").doc(providerId).get();
      const providerToken = providerDoc.data()?.fcmToken;
      if (providerToken) {
        await admin.messaging().send({
          token: providerToken,
          notification: {
            title: "حجز مبدئي جديد! 💼",
            body: "عميل دفع رسم الحجز. يرجى الاستعداد لاستقباله خلال 48 ساعة.",
          },
        });
      }
      return null;
    } catch (error) {
      console.error("خطأ في معالجة رسم الحجز:", error);
      return null;
    }
  });

// ═══════════════════════════════════════════════════════════
// 2. دالة تنظيف الحجوزات المنتهية
// ═══════════════════════════════════════════════════════════
exports.expireUnconfirmedBookings = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const expiredBookings = await admin.firestore()
      .collection("bookings")
      .where("status", "==", "pending_attendance")
      .where("expiresAt", "<=", now)
      .get();

    if (expiredBookings.empty) return null;

    const batch = admin.firestore().batch();
    for (const doc of expiredBookings.docs) {
      const data = doc.data();
      batch.update(doc.ref, {
        status: "expired",
        cancelledBy: "system",
        cancelledAt: now,
        cancellationReason: "لم يتم تأكيد الحجز خلال 48 ساعة",
        refundProcessed: false,
      });

      const dateStr = data.eventDate.toDate().toISOString().split('T')[0];
      const availabilityRef = admin.firestore()
        .collection("availability")
        .doc(`${data.hallId}_${dateStr}`);
      batch.delete(availabilityRef);
    }
    await batch.commit();
    return null;
  });

// ═══════════════════════════════════════════════════════════
// 3. دالة معالجة استرداد الأموال
// ═══════════════════════════════════════════════════════════
exports.onBookingCancelled = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();
    if (previousValue.status === "cancelled" || newValue.status !== "cancelled") return null;
    if (newValue.cancelledBy !== "customer") return null;

    const userId = newValue.userId;
    const bookingId = context.params.bookingId;

    try {
      const now = admin.firestore.Timestamp.now();
      const refundDeadline = newValue.refundEligibleUntil;
      const isEligible = refundDeadline && now.toMillis() <= refundDeadline.toMillis();

      if (isEligible) {
        const walletRef = admin.firestore().collection("wallets").doc(userId);
        await walletRef.set({
          balance: admin.firestore.FieldValue.increment(60.0),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        await admin.firestore().collection("transactions").add({
          userId: userId,
          bookingId: bookingId,
          amount: 60.0,
          type: "refund",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await change.after.ref.update({
          refundProcessed: true,
          refundAmount: 60.0,
        });
      }
      return null;
    } catch (error) {
      console.error("خطأ في الاسترداد:", error);
      return null;
    }
  });

// ═══════════════════════════════════════════════════════════
// 4. دالة إشعار المزود بالحجز الجديد
// ═══════════════════════════════════════════════════════════
exports.onNewBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const bookingData = snap.data();
    const providerId = bookingData.providerId;
    try {
      const providerDoc = await admin.firestore().collection("users").doc(providerId).get();
      const providerToken = providerDoc.data()?.fcmToken;
      if (providerToken) {
        await admin.messaging().send({
          token: providerToken,
          notification: {
            title: "طلب حجز مبدئي جديد ⏳",
            body: "لديك طلب حجز جديد في انتظار دفع رسم الحجز.",
          },
        });
      }
      return null;
    } catch (error) {
      return null;
    }
  });

// ═══════════════════════════════════════════════════════════
// 5. 🆕 استقبال حجوزات من نظام القاعة الخارجي
// ═══════════════════════════════════════════════════════════
exports.receiveExternalBooking = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key');

  if (req.method === 'OPTIONS') return res.status(204).send('');
  if (req.method !== 'POST') return res.status(405).json({ success: false, error: 'Method not allowed' });

  try {
    const { hallId, key } = req.query;
    if (!hallId || !key) return res.status(400).json({ success: false, error: 'Missing hallId or key' });

    const hallDoc = await admin.firestore().collection('halls').doc(hallId).get();
    if (!hallDoc.exists) return res.status(404).json({ success: false, error: 'Hall not found' });

    const hallData = hallDoc.data();
    const integration = hallData.integration || {};
    if (!integration.webhookSecret || integration.webhookSecret !== key) {
      return res.status(401).json({ success: false, error: 'Invalid webhook key' });
    }

    const body = req.body || {};
    const eventDate = body.eventDate;
    const timeSlot = body.timeSlot;
    if (!eventDate || !timeSlot) {
      return res.status(400).json({ success: false, error: 'eventDate and timeSlot are required' });
    }

    if (body.externalId) {
      const existing = await admin.firestore().collection('bookings')
        .where('hallId', '==', hallId)
        .where('externalId', '==', body.externalId)
        .limit(1)
        .get();
      if (!existing.empty) {
        return res.status(200).json({ success: true, message: 'Already exists', bookingId: existing.docs[0].id });
      }
    }

    const eventDateObj = new Date(eventDate + 'T12:00:00Z');
    const bookingRef = admin.firestore().collection('bookings').doc();
    await bookingRef.set({
      userId: `external_${hallId}`,
      hallId: hallId,
      hallName: hallData.name || '',
      hallImage: hallData.image || hallData.coverImage || '',
      eventType: body.eventType || 'حجز من نظام القاعة',
      timeSlot: timeSlot,
      eventDate: admin.firestore.Timestamp.fromDate(eventDateObj),
      guestsCount: body.guestsCount || 0,
      basePrice: 0,
      totalPrice: 0,
      commission: 0,
      providerNet: 0,
      status: 'confirmed',
      paymentStatus: 'external',
      isExternal: true,
      externalId: body.externalId || null,
      customerName: body.customerName || null,
      customerPhone: body.customerPhone || null,
      notes: body.notes || null,
      source: 'hall_system',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await hallDoc.ref.update({
      'integration.lastSync': admin.firestore.FieldValue.serverTimestamp(),
      'integration.lastSyncSuccess': true,
    });

    return res.status(200).json({
      success: true,
      message: 'Booking received successfully',
      bookingId: bookingRef.id,
    });
  } catch (error) {
    console.error('خطأ:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

// ═══════════════════════════════════════════════════════════
// 6. 🆕 إرسال الحجوزات إلى نظام القاعة الخارجي
// ═══════════════════════════════════════════════════════════
exports.notifyHallSystem = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (data.isExternal === true || data.isManual === true) return null;
    const hallId = data.hallId;
    if (!hallId) return null;

    try {
      const hallDoc = await admin.firestore().collection('halls').doc(hallId).get();
      if (!hallDoc.exists) return null;

      const hallData = hallDoc.data();
      const integration = hallData.integration || {};
      if (!integration.isEnabled || !integration.apiUrl || !integration.apiKey) return null;

      const eventDate = data.eventDate.toDate();
      const dateStr = eventDate.toISOString().split('T')[0];

      const payload = {
        bookingId: context.params.bookingId,
        eventDate: dateStr,
        timeSlot: data.timeSlot,
        eventType: data.eventType || '',
        guestsCount: data.guestsCount || 0,
        customerName: data.customerName || '',
        customerPhone: data.customerPhone || '',
        totalPrice: data.totalPrice || 0,
        source: 'farah_app',
      };

      const fetch = require('node-fetch');
      const response = await fetch(integration.apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${integration.apiKey}`,
          'X-API-Key': integration.apiKey,
          'X-Source': 'farah-app',
        },
        body: JSON.stringify(payload),
      });

      const responseText = await response.text();

      await admin.firestore().collection('integration_logs').add({
        hallId: hallId,
        bookingId: context.params.bookingId,
        direction: 'outgoing',
        status: response.ok ? 'success' : 'failed',
        statusCode: response.status,
        responseBody: responseText.substring(0, 2000),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await hallDoc.ref.update({
        'integration.lastSync': admin.firestore.FieldValue.serverTimestamp(),
        'integration.lastSyncSuccess': response.ok,
        'integration.lastError': response.ok ? null : responseText.substring(0, 300),
      });

      return null;
    } catch (error) {
      console.error('خطأ في إرسال حجز:', error);
      return null;
    }
  });
