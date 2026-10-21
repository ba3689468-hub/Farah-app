import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farah/core/constants/app_colors.dart';

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
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حجوزاتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: _uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // ترتيب الحجوزات من الأحدث للأقدم
          final bookings = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aT = (a.data() as Map)['createdAt'] as Timestamp?;
              final bT = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aT == null || bT == null) return 0;
              return bT.compareTo(aT);
            });

          // الفلترة
          final filteredBookings = _filter == 'all'
              ? bookings
              : bookings.where((doc) {
                  final status = (doc.data() as Map)['status'] ?? 'pending';
                  return status == _filter;
                }).toList();

          return Column(
            children: [
              _buildSummaryHeader(bookings),
              _buildFilterTabs(),
              Expanded(
                child: filteredBookings.isEmpty
                    ? const Center(child: Text('لا توجد حجوزات في هذا القسم', style: TextStyle(color: textLight)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, i) {
                          final data = filteredBookings[i].data() as Map<String, dynamic>;
                          return _buildBookingCard(data, filteredBookings[i].id);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<QueryDocumentSnapshot> allBookings) {
    int totalHallPrice = 0;
    for (var doc in allBookings) {
      final data = doc.data() as Map;
      if (data['status'] != 'cancelled') {
        totalHallPrice += (data['totalPrice'] ?? 0) as int;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primary, primaryDark], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('إجمالي الحجوزات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text('${allBookings.length}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: Column(
              children: [
                const Text('إجمالي المبالغ (للقاعات)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text('$totalHallPrice د.ل', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt},
      {'key': 'pending', 'label': 'قيد الانتظار', 'icon': Icons.access_time},
      {'key': 'confirmed', 'label': 'مؤكدة', 'icon': Icons.check_circle},
      {'key': 'completed', 'label': 'مكتملة', 'icon': Icons.done_all},
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
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? primary : primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : primary, size: 16),
                  const SizedBox(width: 6),
                  Text(t['label'] as String, style: TextStyle(color: active ? Colors.white : textDark, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId) {
    final hallName = data['hallName'] ?? 'قاعة';
    final image = data['hallImage'];
    final date = data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null;
    final timeSlot = data['timeSlot'] ?? 'غير محدد';
    final status = data['status'] ?? 'pending';
    final guests = data['guestsCount'] ?? 0;
    final totalPrice = data['totalPrice'] ?? 0;
    
    final refundUntil = data['refundEligibleUntil'] is Timestamp 
        ? (data['refundEligibleUntil'] as Timestamp).toDate() 
        : null;

    final statusInfo = _getStatusInfo(status);
    final bool isPending = status == 'pending' || status == 'pending_attendance';
    
    // ✅ تحديد ما إذا كان الحجز قابلاً للحذف (ملغى أو مكتمل)
    final bool canDelete = status == 'cancelled' || status == 'completed';

    return GestureDetector(
      onTap: () => _showBookingDetails(data, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            // الصورة واسم القاعة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 70, height: 70,
                      child: image != null && image.toString().isNotEmpty
                          ? CachedNetworkImage(imageUrl: image.toString(), fit: BoxFit.cover)
                          : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.celebration, color: primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hallName, style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 14),
                              const SizedBox(width: 4),
                              Text(statusInfo['label'] as String, style: TextStyle(color: statusInfo['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios, color: textLight, size: 16),
                ],
              ),
            ),
            
            // العداد التنازلي
            if (isPending && refundUntil != null)
              RefundCountdownWidget(expiryDate: refundUntil),

            const Divider(height: 1),
            
            // التفاصيل
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _infoItem(Icons.calendar_today, 'التاريخ', date != null ? DateFormat('yyyy/MM/dd').format(date) : '-')),
                      Expanded(child: _infoItem(Icons.access_time, 'الفترة', timeSlot)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _infoItem(Icons.people, 'الضيوف', '$guests ضيف')),
                      Expanded(child: _infoItem(Icons.payments, 'سعر القاعة', '$totalPrice د.ل')),
                    ],
                  ),
                ],
              ),
            ),
            
            // الأزرار (تختلف حسب الحالة)
            if (isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(data, docId),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: primary), foregroundColor: primary),
                        child: const Text('التفاصيل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (status == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _cancelBooking(docId, data),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                          child: const Text('إلغاء الحجز'),
                        ),
                      ),
                  ],
                ),
              )
            // ✅ إضافة أزرار للحجوزات الملغاة والمكتملة (تفاصيل + حذف)
            else if (canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(data, docId),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade400), foregroundColor: textDark),
                        child: const Text('التفاصيل'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBooking(docId),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('حذف السجل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1), 
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primary, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: textLight, fontSize: 10)),
            Text(value, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showBookingDetails(Map<String, dynamic> data, String docId) {
    final services = List<String>.from(data['services'] ?? []);
    final commission = data['commission'] ?? 60;
    final totalPrice = data['totalPrice'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تفاصيل الحجز', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green),
                        SizedBox(width: 8),
                        Text('رسم الحجز (عمولة التطبيق)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('$commission د.ل', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (services.isNotEmpty) ...[
                const Text('الخدمات الإضافية المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [const Icon(Icons.check, size: 16, color: primary), const SizedBox(width: 8), Text(s)]),
                )),
                const Divider(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي سعر القاعة والخدمات (يُدفع للمزود):', style: TextStyle(color: textLight, fontSize: 12)),
                  Text('$totalPrice د.ل', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBooking(String docId, Map<String, dynamic> data) async {
    final expiresAt = data['refundEligibleUntil'] as Timestamp?;

    if (expiresAt == null) {
      _showError('لا يمكن إلغاء هذا الحجز');
      return;
    }

    final isWithin48Hours = DateTime.now().isBefore(expiresAt.toDate());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الحجز'),
        content: Text(
          isWithin48Hours 
            ? 'هل أنت متأكد من إلغاء الحجز؟\nسيتم إرجاع مبلغ 60 د.ل إلى محفظتك فوراً.'
            : 'انتهت مدة الـ 48 ساعة المسموح بها للإلغاء. لا يمكن استرداد رسم الحجز.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
        'status': 'cancelled',
      });

      if (isWithin48Hours) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userSnap = await transaction.get(userRef);
          if (userSnap.exists) {
            final currentBalance = (userSnap.data()?['walletBalance'] ?? 0).toDouble();
            transaction.update(userRef, {'walletBalance': currentBalance + 60.0});
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWithin48Hours ? 'تم الإلغاء واسترداد 60 د.ل للمحفظة' : 'تم إلغاء الحجز بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    }
  }

  // ✅ دالة حذف السجل (الملغى أو المكتمل)
  Future<void> _deleteBooking(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف السجل', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت متأكد من حذف هذا السجل نهائياً من قائمة حجوزاتك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السجل بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('حدث خطأ أثناء الحذف: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed': return {'label': 'مؤكد', 'color': Colors.green, 'icon': Icons.check_circle};
      case 'completed': return {'label': 'مكتمل', 'color': Colors.blue, 'icon': Icons.done_all};
      case 'cancelled': return {'label': 'ملغى', 'color': Colors.redAccent, 'icon': Icons.cancel};
      case 'pending_attendance': return {'label': 'بانتظار الحضور', 'color': Colors.orange, 'icon': Icons.event_available};
      default: return {'label': 'قيد الانتظار', 'color': Colors.orange, 'icon': Icons.access_time};
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('لا توجد لديك حجوزات حتى الآن', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ✅ الويدجت المخصص للعداد التنازلي (الساعات:الدقائق:الثواني)
// ═══════════════════════════════════════════════════════════
class RefundCountdownWidget extends StatefulWidget {
  final DateTime expiryDate;
  const RefundCountdownWidget({super.key, required this.expiryDate});

  @override
  State<RefundCountdownWidget> createState() => _RefundCountdownWidgetState();
}

class _RefundCountdownWidgetState extends State<RefundCountdownWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemaining();
        });
      }
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiryDate)) {
      _remaining = Duration.zero;
      _timer.cancel();
    } else {
      _remaining = widget.expiryDate.difference(now);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inHours < 12 && !isExpired;
    final color = isExpired ? Colors.grey : (isUrgent ? Colors.redAccent : Colors.green);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired 
                ? 'انتهى وقت استرداد رسم الحجز (60 د.ل)' 
                : 'متبقي لاسترداد الرسم: ',
            style: TextStyle(
              color: isExpired ? color : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (!isExpired)
            Text(
              _formatDuration(_remaining),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              
            ),
        ],
      ),
    );
  }
}
