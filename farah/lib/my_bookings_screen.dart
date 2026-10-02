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
  static const Color darkRed = AppColors.primaryDark;
  static const Color cream = AppColors.background;
  static const Color chocolate = AppColors.textPrimary;

  String _filter = 'all';
  late Future<QuerySnapshot> _future;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _future = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('حجوزاتي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildBookingsList()),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'الكل'},
      {'key': 'pending', 'label': 'قيد الانتظار'},
      {'key': 'confirmed', 'label': 'مؤكدة'},
      {'key': 'completed', 'label': 'مكتملة'},
      {'key': 'cancelled', 'label': 'ملغاة'},
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SizedBox(
        height: 38,
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
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: [primary, darkRed])
                      : null,
                  color: active ? null : cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? Colors.transparent
                          : primary.withValues(alpha: 0.2)),
                ),
                child: Text(t['label'] as String,
                    style: TextStyle(
                      color: active ? Colors.white : chocolate,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    )),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return FutureBuilder<QuerySnapshot>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text('تعذر تحميل الحجوزات',
                      style: TextStyle(
                          color: chocolate,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        final filtered = _filter == 'all'
            ? docs
            : docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['status'] == _filter;
              }).toList();

        if (filtered.isEmpty) {
          return _buildEmpty();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            return _buildBookingCard(data, filtered[i].id);
          },
        );
      },
    );
  }

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
              child: const Icon(Icons.event_note_outlined,
                  size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد حجوزات',
                style: TextStyle(
                    color: chocolate,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ابدأ بحجز قاعتك الأولى',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId) {
    final hallName = data['hallName'] ?? 'قاعة بدون اسم';
    final total = data['totalPrice'] ?? 0;
    final guests = data['guestsCount'] ?? 0;
    final status = data['status'] ?? 'pending';
    final eventDate = data['eventDate'] is Timestamp
        ? (data['eventDate'] as Timestamp).toDate()
        : null;

    final statusInfo = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [primary, darkRed]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hallName,
                          style: const TextStyle(
                              color: chocolate,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusInfo['icon'] as IconData,
                              color: statusInfo['color'] as Color, size: 14),
                          const SizedBox(width: 4),
                          Text(statusInfo['label'] as String,
                              style: TextStyle(
                                  color: statusInfo['color'] as Color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _infoItem(
                        Icons.calendar_today,
                        'التاريخ',
                        eventDate != null
                            ? DateFormat('yyyy/MM/dd').format(eventDate)
                            : 'غير محدد')),
                Expanded(
                    child:
                        _infoItem(Icons.people_outline, 'الضيوف', '$guests')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _infoItem(
                        Icons.attach_money, 'الإجمالي', '$total د.ل')),
                const SizedBox(width: 12),
                if (status == 'pending')
                  GestureDetector(
                    onTap: () => _cancelBooking(docId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Text('إلغاء',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: chocolate,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'label': 'مؤكد',
          'color': Colors.green,
          'icon': Icons.check_circle
        };
      case 'completed':
        return {'label': 'مكتمل', 'color': Colors.blue, 'icon': Icons.done_all};
      case 'cancelled':
        return {
          'label': 'ملغى',
          'color': Colors.redAccent,
          'icon': Icons.cancel
        };
      default:
        return {
          'label': 'قيد الانتظار',
          'color': Colors.orange,
          'icon': Icons.access_time
        };
    }
  }

  Future<void> _cancelBooking(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cream,
        title: const Text('إلغاء الحجز',
            textAlign: TextAlign.right, style: TextStyle(color: chocolate)),
        content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': 'cancelled'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إلغاء الحجز'), backgroundColor: Colors.green),
      );
      setState(() {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        _future = FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذر الإلغاء: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }
}
