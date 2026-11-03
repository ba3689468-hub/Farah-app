import 'dart:async';
import 'dart:ui' as ui; // ✅ تمت إضافة هذا السطر لحل مشكلة TextDirection
import 'package:farah/core/constants/app_colors.dart';
import 'package:farah/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'add_edit_hall_screen.dart';
import 'add_manual_booking_screen.dart';
import 'api_integration_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'select_store_type_screen.dart'; 
import 'store_management_screen.dart'; 
import 'auth/presentation/screens/login_screen_farah.dart';

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
  int _currentTab = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchProviderData();
    });
  }

  Future<Map<String, dynamic>> _fetchProviderData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw 'يجب تسجيل الدخول';

    // 1. جلب القاعات
    List<QueryDocumentSnapshot<Map<String, dynamic>>> halls = [];
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

    // 2. جلب الحجوزات
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allBookings = [];
    if (halls.isNotEmpty) {
      final hallIds = halls.map((d) => d.id).toList();
      for (int i = 0; i < hallIds.length; i += 10) {
        final end = (i + 10 > hallIds.length) ? hallIds.length : i + 10;
        final chunk = hallIds.sublist(i, end);
        final snap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('hallId', whereIn: chunk)
            .get();
        allBookings.addAll(snap.docs);
      }
    }

    // 3. تحديث الحجوزات المنتهية تلقائياً
    for (var booking in allBookings) {
      final data = booking.data();
      final status = data['status'] ?? '';
      final eventDate = data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null;

      if (status == 'confirmed' && eventDate != null && eventDate.isBefore(DateTime.now())) {
        try {
          await booking.reference.update({'status': 'completed'});
          data['status'] = 'completed'; 
        } catch (e) {
          debugPrint('Error auto-completing booking: $e');
        }
      }
    }

    // 4. جلب أسماء الزبائن
    final userIds = <String>{};
    for (final b in allBookings) {
      final u = (b.data()['userId'] ?? '') as String;
      if (u.isNotEmpty && !u.startsWith('manual_') && !u.startsWith('external_')) {
        userIds.add(u);
      }
    }
    
    final Map<String, String> userMap = {};
    for (final u in userIds) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(u).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        userMap[u] = data?['fullName'] ?? 'زبون';
      }
    }

    // 5. ترتيب الحجوزات
    allBookings.sort((a, b) {
      final aT = a.data()['createdAt'] as Timestamp?;
      final bT = b.data()['createdAt'] as Timestamp?;
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
      body: SafeArea(
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildDashboardTab(),
            _buildMyHallsTab(),
            _buildBookingsTab(),
            const ProviderProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildProviderBottomNav(),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (snap.hasError) return _buildError(snap.error.toString());

        final data = snap.data!;
        final bookings = data['bookings'] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
        final halls = data['halls'] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
        final userMap = data['userMap'] as Map<String, String>;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar('لوحة المزود')),
            SliverToBoxAdapter(child: _buildStats(bookings)),
            SliverToBoxAdapter(child: _buildQuickActions()),
            
            if (bookings.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أحدث الحجوزات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                      GestureDetector(
                        onTap: () => setState(() => _currentTab = 2),
                        child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = bookings[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBookingCard(b.data(), b.id, userMap, isCompact: true),
                      );
                    },
                    childCount: bookings.length > 3 ? 3 : bookings.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddManualBookingScreen()));
                if (result == true) _loadData();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add_outlined, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('حجز يدوي', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiIntegrationScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.api, color: Colors.purple, size: 20),
                    SizedBox(width: 8),
                    Text('ربط API', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyHallsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (snap.hasError) return _buildError(snap.error.toString());

        final data = snap.data!;
        final halls = data['halls'] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar('قاعاتي')),
            if (halls.isEmpty)
              SliverFillRemaining(child: _buildNoHalls())
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final hall = halls[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildHallFullCard(hall.data(), hall.id),
                      );
                    },
                    childCount: halls.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (snap.hasError) return _buildError(snap.error.toString());

        final data = snap.data!;
        final bookings = data['bookings'] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
        final userMap = data['userMap'] as Map<String, String>;

        final filtered = _filter == 'all'
            ? bookings
            : bookings.where((b) {
                final dataMap = b.data();
                final status = dataMap['status'] ?? 'pending';
                final paymentStatus = dataMap['paymentStatus'] ?? 'unpaid';
                
                if (_filter == 'pending_attendance') {
                  return status == 'pending_attendance' || (status == 'pending' && paymentStatus == 'commission_paid');
                }
                return status == _filter;
              }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar('الحجوزات')),
            SliverToBoxAdapter(child: _buildFilterTabs()),
            if (filtered.isEmpty)
              SliverFillRemaining(child: _buildEmptyBookings())
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildBookingCard(b.data(), b.id, userMap),
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
    );
  }

  Widget _buildAppBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          _providerNotificationButton(),
          
          if (_currentTab == 0 || _currentTab == 1) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('ماذا تريد أن تضيف؟', style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          
                          ListTile(
                            leading: const Icon(Icons.storefront, color: primary, size: 30),
                            title: const Text('إضافة قاعة أفراح', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditHallScreen()));
                              if (result == true) _loadData();
                            },
                          ),
                          const Divider(),
                          
                          ListTile(
                            leading: const Icon(Icons.local_mall, color: Colors.blue, size: 30),
                            title: const Text('إضافة متجر جديد', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectStoreTypeScreen()));
                              if (result == true) _loadData();
                            },
                          ),
                          const Divider(),

                          ListTile(
                            leading: const Icon(Icons.inventory, color: Colors.purple, size: 30),
                            title: const Text('إدارة المتاجر والمنتجات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                            onTap: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen()));
                              if (result == true) _loadData();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, color: primary, size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _providerNotificationButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
                ),
                child: const Icon(Icons.notifications_outlined, color: primary, size: 22),
              ),
              if (count > 0)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderBottomNav() {
    final items = [
      {'icon': Icons.dashboard_outlined, 'active': Icons.dashboard, 'label': 'الرئيسية'},
      {'icon': Icons.storefront_outlined, 'active': Icons.storefront, 'label': 'قاعاتي'},
      {'icon': Icons.event_note_outlined, 'active': Icons.event_note, 'label': 'الحجوزات'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'حسابي'},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 25, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final active = i == _currentTab;
          return GestureDetector(
            onTap: () => setState(() => _currentTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: active ? 12 : 8, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                    color: active ? Colors.white : textLight,
                    size: 20,
                  ),
                  if (active) ...[
                    const SizedBox(width: 5),
                    Text(items[i]['label'] as String,
                        style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStats(List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    int pending = 0;
    int waitingAttendance = 0;
    int confirmed = 0;
    int netProfit = 0;

    for (final b in bookings) {
      final data = b.data();
      final status = data['status'] ?? 'pending';
      final paymentStatus = data['paymentStatus'] ?? 'unpaid';
      final net = (data['providerNet'] ?? 0) is int ? (data['providerNet'] as int) : int.tryParse(data['providerNet'].toString()) ?? 0;
      
      if (status == 'pending' && paymentStatus != 'commission_paid') pending++;
      if (status == 'pending_attendance' || (status == 'pending' && paymentStatus == 'commission_paid')) waitingAttendance++;
      if (status == 'confirmed' || status == 'completed') {
        confirmed++;
        netProfit += net;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(Icons.access_time, 'قيد الانتظار', '$pending', Colors.orange),
              const SizedBox(width: 10),
              _statCard(Icons.event_available, 'بانتظار الحضور', '$waitingAttendance', Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard(Icons.check_circle, 'مؤكدة', '$confirmed', Colors.green),
              const SizedBox(width: 10),
              _statCard(Icons.payments_outlined, 'صافي الأرباح', '$netProfit', primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt},
      {'key': 'pending', 'label': 'جديد', 'icon': Icons.access_time},
      {'key': 'pending_attendance', 'label': 'بانتظار الحضور', 'icon': Icons.event_available},
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
                gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.transparent : primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : primary, size: 14),
                  const SizedBox(width: 6),
                  Text(t['label'] as String,
                      style: TextStyle(fontFamily: 'Tajawal', color: active ? Colors.white : textDark, fontSize: 12,
                          fontWeight: active ? FontWeight.bold : FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHallFullCard(Map<String, dynamic> hall, String hallId) {
    final name = hall['name'] ?? 'قاعة';
    final image = hall['image'] ?? hall['coverImage'];
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final isAvailable = hall['isAvailable'] ?? true;
    final city = hall['city'] ?? 'غير محدد';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                child: SizedBox(
                  width: 120,
                  height: 140,
                  child: (image != null && image.toString().isNotEmpty)
                      ? Image.network(image.toString(), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                          ))
                      : Container(
                          color: primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isAvailable ? 'متاحة' : 'مغلقة',
                                style: TextStyle(fontFamily: 'Tajawal', color: isAvailable ? Colors.green : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: textLight, size: 14),
                          const SizedBox(width: 4),
                          Text(city, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$price د.ل', style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 15, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditHallScreen(hallData: hall, hallId: hallId)));
                      if (result == true) _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: primary, size: 16),
                          SizedBox(width: 6),
                          Text('تعديل القاعة', style: TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _deleteHall(hallId, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _eventTypeInfo(String eventType) {
    switch (eventType) {
      case 'حفل زفاف': return {'icon': Icons.favorite, 'color': const Color(0xFFE91E63)};
      case 'محضر': return {'icon': Icons.home_outlined, 'color': const Color(0xFF9C27B0)};
      case 'عقد قران': case 'فاتحة': return {'icon': Icons.auto_stories_outlined, 'color': const Color(0xFF3F51B5)};
      case 'أسبوع': return {'icon': Icons.child_care_outlined, 'color': const Color(0xFFFF9800)};
      case 'حفل تخرج': return {'icon': Icons.school_outlined, 'color': const Color(0xFF4CAF50)};
      case 'فضانية': return {'icon': Icons.diamond_outlined, 'color': const Color(0xFF009688)};
      default: return {'icon': Icons.celebration_outlined, 'color': primary};
    }
  }

  String _getRemainingTime(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'] as Timestamp?;
    if (expiresAt == null) return 'غير محدد';
    final diff = expiresAt.toDate().difference(DateTime.now());
    if (diff.isNegative) return 'انتهت المدة';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return '$hours ساعة و $minutes دقيقة';
    return '$minutes دقيقة';
  }

  Widget _buildBookingCard(Map<String, dynamic> data, String docId, Map<String, String> userMap, {bool isCompact = false}) {
    final hallName = data['hallName'] ?? 'قاعة';
    final isManual = data['isManual'] == true;
    final customerName = isManual ? (data['customerName'] ?? 'حجز يدوي') : (userMap[data['userId']] ?? 'زبون');
    final total = data['totalPrice'] ?? 0;
    final net = data['providerNet'] ?? 0;
    final guests = data['guestsCount'] ?? 0;
    final status = data['status'] ?? 'pending';
    final paymentStatus = data['paymentStatus'] ?? 'unpaid';
    
    final isActuallyWaiting = status == 'pending_attendance' || (status == 'pending' && paymentStatus == 'commission_paid');
    final displayStatus = isActuallyWaiting ? 'pending_attendance' : status;

    final eventType = data['eventType'] ?? 'مناسبة';
    final timeSlot = data['timeSlot'] ?? '';
    final image = data['hallImage'];
    final eventDate = data['eventDate'] is Timestamp ? (data['eventDate'] as Timestamp).toDate() : null;

    final statusInfo = _statusInfo(displayStatus);
    final statusColor = statusInfo['color'] as Color;
    final statusIcon = statusInfo['icon'] as IconData;
    final statusLabel = statusInfo['label'] as String;
    final eventInfo = _eventTypeInfo(eventType);
    final eventIcon = eventInfo['icon'] as IconData;
    final eventColor = eventInfo['color'] as Color;
    final dateStr = eventDate != null ? DateFormat('yyyy/MM/dd').format(eventDate) : 'غير محدد';
    
    final showCountdown = isActuallyWaiting && !isManual;
    final remainingTime = showCountdown ? _getRemainingTime(data) : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
        border: isManual ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5)
            : (showCountdown ? Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 1.5) : null),
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
                    width: isCompact ? 60 : 70,
                    height: isCompact ? 60 : 70,
                    child: (image != null && image.toString().isNotEmpty)
                        ? Image.network(image.toString(), fit
