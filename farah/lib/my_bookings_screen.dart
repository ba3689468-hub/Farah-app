import 'dart:async';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  String _filter = 'all';
  late Future<QuerySnapshot> _future;
  Timer? _ticker; // ⏰ مؤقت لتحديث العد التنازلي كل ثانية

  @override
  void initState() {
    super.initState();
    _loadBookings();
    // تحديث الشاشة كل ثانية لتحديث العد التنازلي
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _future = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .get();
    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  // ⏰ حساب الوقت المتبقي من الـ 48 ساعة
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> _getRemainingTime(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt == null) {
      return {'expired': true, 'text': 'انتهت المدة', 'hours': 0, 'minutes': 0, 'seconds': 0};
    }

    final now = DateTime.now();
    final expiry = expiresAt.toDate();
    final diff = expiry.difference(now);

    if (diff.isNegative) {
      return {'expired': true, 'text': 'انتهت المدة', 'hours': 0, 'minutes': 0, 'seconds': 0};
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return {
      'expired': false,
      'text': '${hours}س ${minutes}د ${seconds}ث',
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primary));
            }
            if (snap.hasError) {
              return _buildError();
            }

            final docs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            final filtered = _filter == 'all'
                ? docs
                : docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    if (_filter == 'pending') {
                      return status == 'pending' || status == 'pending_attendance';
                    }
                    return status == _filter;
                  }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSummary(docs)),
                SliverToBoxAdapter(child: _buildFilterTabs()),
                filtered.isEmpty
                    ? SliverFillRemaining(child: _buildEmpty())
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final data = filtered[i].data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildBookingCard(data, filtered[i].id),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── الهيدر ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          const Text(
            'حجوزاتي',
            style: TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadBookings,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_note, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ── ملخص الحجوزات ──
  Widget _buildSummary(List<QueryDocumentSnapshot> docs) {
    int total = 0;
    int active = 0;

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final price = (data['totalPrice'] ?? 0);
      total += (price is int ? price : int.tryParse(price.toString()) ?? 0);
      final status = data['status'] ?? '';
      if (status == 'pending' || status == 'pending_attendance' || status == 'confirmed') {
        active++;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.book_online, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('إجمالي الحجوزات',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${docs.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('إجمالي المبالغ',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('$total د.ل',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── شرائح الفلترة ──
  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt},
      {'key': 'pending', 'label': 'قيد الانتظار', 'icon': Icons.access_time},
      {'key': 'confirmed', 'label': 'مؤكدة', 'icon': Icons.check_circle},
      {'key': 'completed', 'label': 'مكتملة', 'icon': Icons.done_all},
      {'key': 'expired', 'label': 'منتهية', 'icon': Icons.timer_off},
      {'key': 'cancelled', 'label': 'ملغاة', 'icon': Icons.cancel},
    ];

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final active = t['key'] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = t['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(colors: [primary, primaryDark])
                    : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? Colors.transparent : primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData,
                      color: active ? Colors.white : primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    t['label'] as String,
                    style: TextStyle(
                      color: active ? Colors.white : textDark,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── بطاقة الحجز (مع العد التنازلي) ──
  // ═══════════════════════════════════════════════════════════
  Widget _buildBookingCard(Map<String, dynamic> data, String docId) {
    final hallName = data['hallName'] ?? 'قاعة بدون اسم';
    final total = data['totalPrice'] ?? 0;
    final guests = data['guestsCount'] ?? 0;
    final status = data['status'] ?? 'pending';
    final image = data['hallImage'] ?? data['image'];
    final eventDate = data['eventDate'] is Timestamp
        ? (data['eventDate'] as Timestamp).toDate()
        : null;

    final statusInfo = _statusInfo(status);
    final statusColor = statusInfo['color'] as Color;
    final statusIcon = statusInfo['icon'] as IconData;
    final statusLabel = statusInfo['label'] as String;

    // ⏰ الوقت المتبقي
    final remaining = _getRemainingTime(data);
    final isPendingActive = status == 'pending_attendance' && remaining['expired'] == false;
    final showCancelButton = isPendingActive;
    final timeExpired = status == 'pending_attendance' && remaining['expired'] == true;

    // لون العد التنازلي حسب الوقت المتبقي
    Color countdownColor;
    if (remaining['hours'] >= 24) {
      countdownColor = Colors.green;
    } else if (remaining['hours'] >= 12) {
      countdownColor = Colors.orange;
    } else {
      countdownColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── الجزء العلوي: الصورة والاسم ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: image != null
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.celebration, color: primary, size: 30),
                            ),
                          )
                        : Container(
                            color: primary.withValues(alpha: 0.15),
                            child: const Icon(Icons.celebration, color: primary, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hallName,
                        style: const TextStyle(
                            color: textDark, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusLabel,
                              style: TextStyle(
                                  color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(statusIcon, color: statusColor, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⏰ شريط العد التنازلي (يظهر فقط للحجوزات قيد الانتظار النشطة)
          if (isPendingActive)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: countdownColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: countdownColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: countdownColor, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الوقت المتبقي للتوجه للقاعة:',
                      style: TextStyle(color: textDark, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: countdownColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      remaining['text'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // ⏰ شريط "انتهى الحجز" إذا انتهت المدة
          if (timeExpired)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_off_outlined, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'انتهت مدة الـ 48 ساعة - لا يمكن الاسترداد',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),

          // ── التفاصيل ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                        Icons.calendar_today_outlined,
                        'التاريخ',
                        eventDate != null ? DateFormat('yyyy/MM/dd').format(eventDate) : 'غير محدد',
                      ),
                    ),
                    Expanded(
                      child: _infoItem(Icons.people_outline, 'الضيوف', '$guests ضيف'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.attach_money, 'الإجمالي', '$total د.ل'),
                    ),
                    // ✅ زر الإلغاء (يظهر فقط خلال الـ 48 ساعة)
                    if (showCancelButton)
                      GestureDetector(
                        onTap: () => _cancelBooking(docId, remaining['text'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'إلغاء',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── عنصر معلومات ──
  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: textLight, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ── حالة الحجز ──
  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {'label': 'مؤكد', 'color': Colors.green, 'icon': Icons.check_circle};
      case 'completed':
        return {'label': 'مكتمل', 'color': Colors.blue, 'icon': Icons.done_all};
      case 'cancelled':
        return {'label': 'ملغى', 'color': Colors.redAccent, 'icon': Icons.cancel};
      case 'expired':
        return {'label': 'منتهي', 'color': Colors.grey, 'icon': Icons.timer_off};
      case 'pending_attendance':
        return {'label': 'بانتظار الحضور', 'color': Colors.orange, 'icon': Icons.access_time};
      default:
        return {'label': 'قيد الانتظار', 'color': Colors.orange, 'icon': Icons.access_time};
    }
  }

  // ── لا توجد حجوزات ──
  Widget _buildEmpty() {
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
              child: const Icon(Icons.event_note_outlined, size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد حجوزات',
                style: TextStyle(
                    color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ابدأ بحجز قاعتك الأولى',
                style: TextStyle(color: textLight, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── خطأ ──
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('تعذر تحميل الحجوزات',
                style: TextStyle(
                    color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(_loadBookings),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary, foregroundColor: Colors.white),
              child: const Text('حاول مرة أخرى'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ── إلغاء الحجز (مع سياسة الاسترداد) ──
  // ═══════════════════════════════════════════════════════════
  Future<void> _cancelBooking(String docId, String remainingTime) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 26),
            SizedBox(width: 10),
            Text('إلغاء الحجز', style: TextStyle(color: textDark, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من إلغاء هذا الحجز؟',
              style: TextStyle(color: textDark, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم استرداد 60 د.ل كاملة إلى محفظتك',
                      style: TextStyle(
                          color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'الوقت المتبقي: $remainingTime',
              style: const TextStyle(color: textLight, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('تراجع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ✅ تحديث الحجز مع الإشارة إلى أن العميل هو من ألغى
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
        'status': 'cancelled',
        'cancelledBy': 'customer', // ← مهم جداً لتشغيل Cloud Function للاسترداد
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': 'إلغاء من العميل',
      });

      if (!mounted) return;

      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم إلغاء الحجز. سيتم استرداد 60 د.ل إلى محفظتك خلال لحظات.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      _loadBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذر الإلغاء: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
