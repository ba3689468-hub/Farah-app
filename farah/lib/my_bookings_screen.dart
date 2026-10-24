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
  
  String _filter = 'all';
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    // ✅ جلب الألوان من الثيم الحالي (فاتح أو داكن)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : AppColors.textPrimary);
    final textLight = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('حجوزاتي', style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontWeight: FontWeight.w800, fontSize: 20)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 26),
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
            return _buildEmptyState(textColor, textLight);
          }

          final bookings = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aT = (a.data() as Map)['createdAt'] as Timestamp?;
              final bT = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aT == null || bT == null) return 0;
              return bT.compareTo(aT);
            });

          final filteredBookings = _filter == 'all'
              ? bookings
              : bookings.where((doc) {
                  final status = (doc.data() as Map)['status'] ?? 'pending';
                  return status == _filter;
                }).toList();

          return Column(
            children: [
              _buildSummaryHeader(bookings, textColor),
              _buildFilterTabs(isDark, cardColor, textColor, textLight),
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(child: Text('لا توجد حجوزات في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textLight)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, i) {
                          final data = filteredBookings[i].data() as Map<String, dynamic>;
                          return _buildBookingCard(data, filteredBookings[i].id, isDark, cardColor, textColor, textLight);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<QueryDocumentSnapshot> allBookings, Color textColor) {
    int totalHallPrice = 0;
    for (var doc in allBookings) {
      final data = doc.data() as Map;
      if (data['status'] != 'cancelled') {
        totalHallPrice += (data['totalPrice'] ?? 0) as int;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primary, primaryDark], begin: Alignment.topRight, end: Alignment.bottomLeft),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('إجمالي الحجوزات', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text('${allBookings.length}', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white30),
          Expanded(
            child: Column(
              children: [
                const Text('إجمالي المبالغ (للقاعات)', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text('$totalHallPrice د.ل', style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark, Color cardColor, Color textColor, Color textLight) {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.grid_view_rounded},
      {'key': 'pending', 'label': 'قيد الانتظار', 'icon': Icons.access_time_rounded},
      {'key': 'confirmed', 'label': 'مؤكدة', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'completed', 'label': 'مكتملة', 'icon': Icons.done_all_rounded},
      {'key': 'cancelled', 'label': 'ملغاة', 'icon': Icons.cancel_outlined},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final active = t['key'] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = t['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? primary : cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: active ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : textLight, size: 16),
                  const SizedBox(width: 6),
                  Text(t['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: active ? Colors.white : textColor, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId, bool isDark, Color cardColor, Color textColor, Color textLight) {
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
    final bool canDelete = status == 'cancelled' || status == 'completed';

    return GestureDetector(
      onTap: () => _showBookingDetails(data, docId, isDark, textColor, textLight),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
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
                          : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.celebration, color: primary, size: 30)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hallName, style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 12),
                              const SizedBox(width: 4),
                              Text(statusInfo['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: statusInfo['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey, size: 16),
                ],
              ),
            ),
            
            if (isPending && refundUntil != null)
              RefundCountdownWidget(expiryDate: refundUntil),

            Divider(height: 1, thickness: 1, color: isDark ? Colors.grey.shade800 : const Color(0xFFF0F0F0)),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem(Icons.calendar_today_rounded, 'التاريخ', date != null ? DateFormat('yyyy/MM/dd').format(date) : '-', textColor, textLight),
                  _infoItem(Icons.access_time_rounded, 'الفترة', timeSlot, textColor, textLight),
                  _infoItem(Icons.people_alt_rounded, 'الضيوف', '$guests', textColor, textLight),
                ],
              ),
            ),
            
            // ✅ تصميم الأزرار المحسن
            if (isPending || canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(data, docId, isDark, textColor, textLight),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.2),
                          foregroundColor: primary,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('التفاصيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (status == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _cancelBooking(docId, data, textColor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    if (canDelete)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteBooking(docId),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1), 
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _infoItem(IconData icon, String label, String value, Color textColor, Color textLight) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: primary, size: 14),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 9)),
            Text(value, style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // الدوال المساعدة (محدثة لتستقبل الألوان)
  void _showBookingDetails(Map<String, dynamic> data, String docId, bool isDark, Color textColor, Color textLight) {
    final services = List<String>.from(data['services'] ?? []);
    final commission = data['commission'] ?? 60;
    final totalPrice = data['totalPrice'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفاصيل الحجز', style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
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
                        Text('رسم الحجز (عمولة التطبيق)', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('$commission د.ل', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (services.isNotEmpty) ...[
                Text('الخدمات الإضافية المطلوبة:', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [const Icon(Icons.check, size: 16, color: primary), const SizedBox(width: 8), Text(s, style: TextStyle(fontFamily: 'Tajawal', color: textColor))]),
                )),
                const Divider(height: 24),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('إجمالي سعر القاعة والخدمات (يُدفع للمزود):', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                  Text('$totalPrice د.ل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                ],
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBooking(String docId, Map<String, dynamic> data, Color textColor) async {
    final expiresAt = data['refundEligibleUntil'] as Timestamp?;
    if (expiresAt == null) { _showError('لا يمكن إلغاء هذا الحجز'); return; }
    final isWithin48Hours = DateTime.now().isBefore(expiresAt.toDate());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إلغاء الحجز', style: TextStyle(fontFamily: 'Tajawal', color: textColor)),
        content: Text(
          isWithin48Hours ? 'هل أنت متأكد من إلغاء الحجز؟\nسيتم إرجاع مبلغ 60 د.ل إلى محفظتك فوراً.' : 'انتهت مدة الـ 48 ساعة المسموح بها للإلغاء.',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'cancelled'});
      if (isWithin48Hours) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userSnap = await transaction.get(userRef);
          if (userSnap.exists) {
            final currentBalance = (userSnap.data()?['walletBalance'] ?? 0).toDouble();
            transaction.update(userRef, {'walletBalance': currentBalance + 60.0});
          }
        });
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': _uid, 'amount': 60.0, 'type': 'refund', 'description': 'استرداد رسم حجز (إلغاء)', 'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isWithin48Hours ? 'تم الإلغاء واسترداد 60 د.ل' : 'تم إلغاء الحجز', style: const TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green),
        );
      }
    } catch (e) { _showError('حدث خطأ: $e'); }
  }

  Future<void> _deleteBooking(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف السجل', style: TextStyle(color: Colors.redAccent, fontFamily: 'Tajawal')),
        content: const Text('هل أنت متأكد من حذف هذا السجل نهائياً؟', style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، احذف', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف السجل', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green));
    } catch (e) { _showError('حدث خطأ: $e'); }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.redAccent));
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

  Widget _buildEmptyState(Color textColor, Color textLight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('لا توجد لديك حجوزات حتى الآن', style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class RefundCountdownWidget extends StatefulWidget {
  final DateTime expiryDate;
  const RefundCountdownWidget({super.key, required this.expiryDate});

  @override
  State<RefundCountdownWidget> createState() => _RefundCountdownWidgetState();
}

class _RefundCountdownWidgetState extends State<RefundCountdownWidget> {
  Timer? _timer; 
  Duration _remaining = Duration.zero; 

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _calculateRemaining());
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    if (now.isAfter(widget.expiryDate)) {
      _remaining = Duration.zero;
      _timer?.cancel(); 
    } else {
      _remaining = widget.expiryDate.difference(now);
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inHours < 12 && !isExpired;
    final color = isExpired ? Colors.grey : (isUrgent ? Colors.redAccent : Colors.green);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isExpired ? Icons.timer_off_rounded : Icons.timer_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            isExpired ? 'انتهى وقت استرداد رسم الحجز (60 د.ل)' : 'متبقي لاسترداد الرسم: ',
            style: TextStyle(fontFamily: 'Tajawal', color: isExpired ? color : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: isExpired ? FontWeight.bold : FontWeight.w600),
          ),
          if (!isExpired)
            Text(
              _formatDuration(_remaining),
              style: TextStyle(fontFamily: 'Tajawal', color: color, fontSize: 16, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
        ],
      ),
    );
  }
}
