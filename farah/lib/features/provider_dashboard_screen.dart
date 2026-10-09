import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  late Future<Map<String, dynamic>> _dataFuture;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchProviderData();
    });
  }

  Future<Map<String, dynamic>> _fetchProviderData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw 'no user';

    // ── جلب قاعات المزود ──
    List<QueryDocumentSnapshot> halls = [];
    for (final field in ['providerId', 'ownerId', 'userId']) {
      final snap = await FirebaseFirestore.instance
          .collection('halls')
          .where(field, isEqualTo: uid)
          .get();
      if (snap.docs.isNotEmpty) {
        halls = snap.docs;
        break;
      }
    }

    if (halls.isEmpty) {
      return {
        'halls': <QueryDocumentSnapshot>[],
        'bookings': <QueryDocumentSnapshot>[],
        'userMap': <String, String>{},
      };
    }

    final hallIds = halls.map((d) => d.id).toList();

    // ── جلب الحجوزات (مع تقسيم whereIn إلى مجموعات من 10) ──
    final List<QueryDocumentSnapshot> allBookings = [];
    for (int i = 0; i < hallIds.length; i += 10) {
      final end = (i + 10 > hallIds.length) ? hallIds.length : i + 10;
      final chunk = hallIds.sublist(i, end);
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('hallId', whereIn: chunk)
          .get();
      allBookings.addAll(snap.docs);
    }

    // ── جلب أسماء الزبائن ──
    final userIds = <String>{};
    for (final b in allBookings) {
      final u = (b.data()['userId'] ?? '') as String;
      if (u.isNotEmpty) userIds.add(u);
    }
    final Map<String, String> userMap = {};
    for (final u in userIds) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u)
          .get();
      if (doc.exists) {
        userMap[u] = doc.data()?['fullName'] ?? 'مستخدم';
      }
    }

    // ── ترتيب الحجوزات حسب التاريخ ──
    allBookings.sort((a, b) {
      final aT = (a.data() as Map)['createdAt'] as Timestamp?;
      final bT = (b.data() as Map)['createdAt'] as Timestamp?;
      if (aT == null && bT == null) return 0;
      if (aT == null) return 1;
      if (bT == null) return -1;
      return bT.compareTo(aT);
    });

    return {
      'halls': halls,
      'bookings': allBookings,
      'userMap': userMap,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text('لوحة المزود',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textDark)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: primary));
            }
            if (snap.hasError) {
              return _buildError();
            }

            final data = snap.data!;
            final halls = data['halls'] as List<QueryDocumentSnapshot>;
            final bookings = data['bookings'] as List<QueryDocumentSnapshot>;
            final userMap = data['userMap'] as Map<String, String>;

            if (halls.isEmpty) return _buildNoHalls();

            final filtered = _filter == 'all'
                ? bookings
                : bookings.where((b) {
                    final s = (b.data() as Map)['status'] ?? 'pending';
                    return s == _filter;
                  }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                _loadData();
                await _dataFuture;
              },
              color: primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStats(bookings)),
                  SliverToBoxAdapter(child: _buildFilterTabs()),
                  filtered.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyBookings())
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final b = filtered[i];
                                final bData =
                                    b.data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildBookingCard(bData, b.id, userMap),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── إحصائيات سريعة ──
  Widget _buildStats(List<QueryDocumentSnapshot> bookings) {
    int pending = 0;
    int confirmed = 0;
    int netProfit = 0;

    for (final b in bookings) {
      final data = b.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      final net = (data['providerNet'] ?? 0) is int
          ? (data['providerNet'] as int)
          : int.tryParse(data['providerNet'].toString()) ?? 0;
      if (status == 'pending') pending++;
      if (status == 'confirmed' || status == 'completed') {
        confirmed++;
        netProfit += net;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _statCard(Icons.access_time, 'قيد الانتظار', '$pending',
              Colors.orange),
          const SizedBox(width: 10),
          _statCard(Icons.check_circle, 'مؤكدة', '$confirmed',
              Colors.green),
          const SizedBox(width: 10),
          _statCard(Icons.payments_outlined, 'صافي الأرباح', '$netProfit',
              primary),
        ],
      ),
    );
  }

  Widget _statCard(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: textLight, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [primary, primaryDark])
                    : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData,
                      color: active ? Colors.white : primary,
                      size: 14),
                  const SizedBox(width: 6),
                  Text(t['label'] as String,
                      style: TextStyle(
                          color: active ? Colors.white : textDark,
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── بطاقة الحجز ──
  Widget _buildBookingCard(Map<String, dynamic> data, String docId,
      Map<String, String> userMap) {
    final hallName = data['hallName'] ?? 'قاعة';
    final customerName = userMap[data['userId']] ?? 'زبون';
    final total = data['totalPrice'] ?? 0;
    final net = data['providerNet'] ?? 0;
    final guests = data['guestsCount'] ?? 0;
    final status = data['status'] ?? 'pending';
    final eventType = data['eventType'] ?? 'مناسبة';
    final timeSlot = data['timeSlot'] ?? '';
    final image = data['hallImage'];
    final eventDate = data['eventDate'] is Timestamp
        ? (data['eventDate'] as Timestamp).toDate()
        : null;

    final statusInfo = _statusInfo(status);
    final statusColor = statusInfo['color'] as Color;
    final statusIcon = statusInfo['icon'] as IconData;
    final statusLabel = statusInfo['label'] as String;

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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: (image != null && image.toString().isNotEmpty)
                        ? Image.network(image.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.celebration,
                                  color: primary, size: 30),
                            ))
                        : Container(
                            color: primary.withValues(alpha: 0.15),
                            child: const Icon(Icons.celebration,
                                color: primary, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(hallName,
                          style: const TextStyle(
                              color: textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(customerName,
                              style: const TextStyle(
                                  color: textLight, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.person_outline,
                              color: textLight, size: 13),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(statusIcon,
                                color: statusColor, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.black.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.calendar_today_outlined,
                          'التاريخ',
                          eventDate != null
                              ? DateFormat('yyyy/MM/dd').format(eventDate)
                              : 'غير محدد'),
                    ),
                    Expanded(
                      child: _infoItem(Icons.people_outline, 'الضيوف',
                          '$guests ضيف'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.celebration_outlined,
                          'المناسبة', eventType),
                    ),
                    Expanded(
                      child: _infoItem(Icons.access_time,
                          'الفترة', timeSlot.isNotEmpty ? timeSlot : '-'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(
                          Icons.attach_money, 'الإجمالي', '$total د.ل'),
                    ),
                    Expanded(
                      child: _infoItem(Icons.payments_outlined,
                          'صافي ربحك', '$net د.ل'),
                    ),
                  ],
                ),
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _updateBookingStatus(docId, 'cancelled'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.redAccent
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close,
                                    color: Colors.redAccent, size: 16),
                                SizedBox(width: 6),
                                Text('رفض',
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _updateBookingStatus(docId, 'confirmed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 6),
                                Text('قبول',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: textLight, fontSize: 9)),
              Text(value,
                  style: const TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // ── تحديث حالة الحجز ──
  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    final isConfirm = newStatus == 'confirmed';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(isConfirm ? 'تأكيد الحجز' : 'رفض الحجز',
            textAlign: TextAlign.right,
            style: const TextStyle(color: textDark)),
        content: Text(
          isConfirm
              ? 'هل تريد تأكيد هذا الحجز؟'
              : 'هل تريد رفض هذا الحجز؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isConfirm ? Colors.green : Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isConfirm ? 'نعم، تأكيد' : 'نعم، رفض'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': newStatus});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isConfirm
              ? '✅ تم تأكيد الحجز'
              : '✅ تم رفض الحجز'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  // ── لا توجد قاعات ──
  Widget _buildNoHalls() {
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
              child: const Icon(Icons.storefront_outlined,
                  size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد قاعات مسجلة',
                style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أضف قاعتك الأولى من إعدادات حسابك',
                style: TextStyle(color: textLight, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── لا توجد حجوزات ──
  Widget _buildEmptyBookings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 70, color: primary.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            const Text('لا توجد حجوزات',
                style: TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('تعذر تحميل بيانات المزود',
              style: TextStyle(color: textDark, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حاول مرة أخرى'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'label': 'مؤكد',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'completed':
        return {
          'label': 'مكتمل',
          'color': Colors.blue,
          'icon': Icons.done_all,
        };
      case 'cancelled':
        return {
          'label': 'ملغى',
          'color': Colors.redAccent,
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': 'قيد الانتظار',
          'color': Colors.orange,
          'icon': Icons.access_time,
        };
    }
  }
}
