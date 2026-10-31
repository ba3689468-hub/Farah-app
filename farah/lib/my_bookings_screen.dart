import 'dart:async'; 
import 'dart:ui'; // مطلوب لـ FontFeature
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
  
  String _filter = 'all';
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : AppColors.textPrimary);
    final textLight = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text('حجوزاتي', style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontWeight: FontWeight.w800, fontSize: 20)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 24),
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
              _buildSummaryHeader(bookings, isDark, cardColor, textColor, textLight),
              _buildFilterTabs(isDark, cardColor, textColor, textLight),
              Expanded(
                child: filteredBookings.isEmpty
                    ? Center(child: Text('لا توجد حجوزات في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 15)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 8),
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

  // ✅ هيدر أنيق وخفيف
  Widget _buildSummaryHeader(List<QueryDocumentSnapshot> allBookings, bool isDark, Color cardColor, Color textColor, Color textLight) {
    int totalHallPrice = 0;
    for (var doc in allBookings) {
      final data = doc.data() as Map;
      if (data['status'] != 'cancelled') {
        totalHallPrice += (data['totalPrice'] ?? 0) as int;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('إجمالي الحجوزات', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${allBookings.length}', style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          Expanded(
            child: Column(
              children: [
                Text('إجمالي المبالغ (للقاعات)', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('$totalHallPrice د.ل', style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ أزرار التصفية بشكل أنظف
  Widget _buildFilterTabs(bool isDark, Color cardColor, Color textColor, Color textLight) {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.grid_view_rounded},
      {'key': 'pending', 'label': 'قيد الانتظار', 'icon': Icons.access_time_rounded},
      {'key': 'confirmed', 'label': 'مؤكدة', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'completed', 'label': 'مكتملة', 'icon': Icons.done_all_rounded},
      {'key': 'cancelled', 'label': 'ملغاة', 'icon': Icons.cancel_outlined},
    ];

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                boxShadow: active ? [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                border: Border.all(color: active ? primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : textLight, size: 15),
                  const SizedBox(width: 6),
                  Text(t['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: active ? Colors.white : textColor, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ بطاقة الحجز بالتصميم الجديد
  Widget _buildBookingCard(Map<String, dynamic> data, String docId, bool isDark, Color cardColor, Color textColor, Color textLight) {
    final hallName = data['hallName'] ?? 'قاعة';
    final image = data['hallImage'];
    final date = data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null;
    final timeSlot = data['timeSlot'] ?? 'غير محدد';
    final status = data['status'] ?? 'pending';
    final guests = data['guestsCount'] ?? 0;
    
    final refundUntil = data['refundEligibleUntil'] is Timestamp 
        ? (data['refundEligibleUntil'] as Timestamp).toDate() 
        : null;

    final statusInfo = _getStatusInfo(status);
    final bool isPending = status == 'pending' || status == 'pending_attendance';
    final bool canDelete = status == 'cancelled' || status == 'completed';

    return GestureDetector(
      onTap: () => _showBookingDetails(data, docId, isDark, textColor, textLight),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03), 
              blurRadius: 15, 
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          children: [
            // القسم العلوي: الصورة والاسم والحالة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 75, height: 75,
                      child: image != null && image.toString().isNotEmpty
                          ? CachedNetworkImage(imageUrl: image.toString(), fit: BoxFit.cover)
                          : Container(color: primary.withValues(alpha: 0.1), child: const Icon(Icons.celebration, color: primary, size: 30)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hallName, style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 14),
                              const SizedBox(width: 4),
                              Text(statusInfo['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: statusInfo['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_back_ios_new_rounded, color: textLight, size: 16),
                ],
              ),
            ),
            
            // ✅ التعديل هنا: شريط العد التنازلي
            if (isPending && refundUntil != null)
              RefundCountdownWidget(expiryDate: refundUntil),

            // ✅ صندوق المعلومات (التاريخ، الفترة، الضيوف)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoItem(Icons.calendar_month_rounded, 'التاريخ', date != null ? DateFormat('yyyy/MM/dd').format(date) : '-', textColor, textLight),
                    _divider(isDark),
                    _infoItem(Icons.schedule_rounded, 'الفترة', timeSlot, textColor, textLight),
                    _divider(isDark),
                    _infoItem(Icons.people_alt_rounded, 'الضيوف', '$guests', textColor, textLight),
                  ],
                ),
              ),
            ),
            
            // ✅ الأزرار
            if (isPending || canDelete)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _showBookingDetails(data, docId, isDark, textColor, textLight),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary.withValues(alpha: 0.1),
                          foregroundColor: primary,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('التفاصيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (status == 'pending')
                      Expanded(
                        flex: 1,
                        child: TextButton(
                          onPressed: () => _cancelBooking(docId, data, textColor),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    if (canDelete)
                      Expanded(
                        flex: 1,
                        child: TextButton.icon(
                          onPressed: () => _deleteBooking(docId),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('حذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            minimumSize: const Size(0, 44),
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

  Widget _divider(bool isDark) => Container(width: 1, height: 25, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300);

  Widget _infoItem(IconData icon, String label, String value, Color textColor, Color textLight) {
    return Row(
      children: [
        Icon(icon, color: primary.withValues(alpha: 0.8), size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontFamily: 'Tajawal', color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

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
                  style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
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
          isWithin48Hours ? 'هل أنت متأكد من إلغاء الحجز؟\nسيتم إرجاع مبلغ 60 د.ل إلى محفظتك فوراً.' : 'انتهت مدة الـ 48 ساعة المسموح بها للإلغاء، لن يتم استرداد الرسم.',
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

// ✅ كلاس شريط العد التنازلي المعدل (حل التناقض)
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
    
    // إذا انتهى الوقت، نعرض رسالة صغيرة جداً وهادئة بدلاً من الشريط الرمادي الضخم
    if (isExpired) {
       return Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
         child: Row(
           children: [
             Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
             const SizedBox(width: 6),
             Text(
               'انتهت مدة استرداد الرسم (60 د.ل)',
               style: TextStyle(
                 fontFamily: 'Tajawal', 
                 fontSize: 11, 
                 color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
               ),
             ),
           ],
         ),
       );
    }

    final color = isUrgent ? Colors.redAccent : Colors.green;
    
    // شريط العد التنازلي النشط
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            'متبقي لاسترداد الرسم: ',
            style: TextStyle(fontFamily: 'Tajawal', color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            _formatDuration(_remaining),
            style: TextStyle(fontFamily: 'Tajawal', color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}
