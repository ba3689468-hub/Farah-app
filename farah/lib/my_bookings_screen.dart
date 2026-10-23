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
  static const Color bgColor = Color(0xFFF9F9FB);

  String _filter = 'all';
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('حجوزاتي', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 20)),
        iconTheme: const IconThemeData(color: textDark),
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
            return _buildEmptyState();
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
              _buildSummaryHeader(bookings),
              _buildFilterTabs(),
              Expanded(
                child: filteredBookings.isEmpty
                    ? const Center(child: Text('لا توجد حجوزات في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textLight)))
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

  Widget _buildFilterTabs() {
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
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: active ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : textLight, size: 16),
                  const SizedBox(width: 6),
                  Text(t['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: active ? Colors.white : textDark, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
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
    final bool canDelete = status == 'cancelled' || status == 'completed';

    return GestureDetector(
      onTap: () => _showBookingDetails(data, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            // الجزء العلوي (الصورة والاسم)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 80, height: 80,
                      child: image != null && image.toString().isNotEmpty
                          ? CachedNetworkImage(imageUrl: image.toString(), fit: BoxFit.cover)
                          : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.celebration, color: primary, size: 40)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hallName, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 14),
                              const SizedBox(width: 6),
                              Text(statusInfo['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: statusInfo['color'] as Color, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios_new_rounded, color: textLight, size: 18),
                ],
              ),
            ),
            
            // العداد التنازلي
            if (isPending && refundUntil != null)
              RefundCountdownWidget(expiryDate: refundUntil),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            
            // تفاصيل الحجز (شبكة)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _infoItem(Icons.calendar_today_rounded, 'التاريخ', date != null ? DateFormat('yyyy/MM/dd').format(date) : '-')),
                      Expanded(child: _infoItem(Icons.access_time_rounded, 'الفترة', timeSlot)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _infoItem(Icons.people_alt_rounded, 'الضيوف', '$guests ضيف')),
                      Expanded(child: _infoItem(Icons.payments_rounded, 'سعر القاعة', '$totalPrice د.ل')),
                    ],
                  ),
                ],
              ),
            ),
            
            // الأزرار
            if (isPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(data, docId),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.5),
                          foregroundColor: primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('التفاصيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (status == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _cancelBooking(docId, data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                  ],
                ),
              )
            else if (canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showBookingDetails(data, docId),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                          foregroundColor: textDark,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('التفاصيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBooking(docId),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        label: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1), 
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: primary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ... (باقي الدوال المساعدة مثل _showBookingDetails, _cancelBooking, _deleteBooking, _getStatusInfo تبقى كما هي) ...
  // لضمان عدم الإطالة، سأضع لك الدوال الأساسية فقط هنا، ويمكنك نسخها من الكود القديم
  // أو طلب الكود كاملاً إذا واجهت مشكلة.
  
  // (نسخ الدوال من الكود القديم هنا)
  void _showBookingDetails(Map<String, dynamic> data, String docId) { /* ... الكود القديم ... */ }
  Future<void> _cancelBooking(String docId, Map<String, dynamic> data) async { /* ... الكود القديم ... */ }
  Future<void> _deleteBooking(String docId) async { /* ... الكود القديم ... */ }
  void _showError(String msg) { /* ... الكود القديم ... */ }
  Map<String, dynamic> _getStatusInfo(String status) { /* ... الكود القديم ... */ }
  Widget _buildEmptyState() { /* ... الكود القديم ... */ }
}

class RefundCountdownWidget extends StatefulWidget {
  // ... الكود القديم ...
  final DateTime expiryDate;
  const RefundCountdownWidget({super.key, required this.expiryDate});

  @override
  State<RefundCountdownWidget> createState() => _RefundCountdownWidgetState();
}

class _RefundCountdownWidgetState extends State<RefundCountdownWidget> {
  // ... الكود القديم ...
  Timer? _timer; 
  Duration _remaining = Duration.zero; 

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer?.cancel(); 
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
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isExpired 
                ? 'انتهى وقت استرداد رسم الحجز (60 د.ل)' 
                : 'متبقي لاسترداد الرسم: ',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: isExpired ? color : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: isExpired ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          if (!isExpired)
            Text(
              _formatDuration(_remaining),
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}
