import 'dart:async';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'features/auth/presentation/screens/login_screen_farah.dart';
import 'features/favorites_screen.dart';
import 'features/explore_screen.dart';
import 'features/edit_profile_screen.dart';
import 'features/wallet_screen.dart';
import 'features/notifications_screen.dart';
import 'features/provider_dashboard_screen.dart';
import 'hall_details_screen.dart';
import 'my_bookings_screen.dart';
import 'stores_list_screen.dart'; // ✅ تمت إضافة استيراد شاشة المتاجر

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});
  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  int _currentIndex = 0;
  bool _isGrid = false;
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _minRating = 0;
  String _selectedType = 'الكل';
  String _selectedCity = 'الكل';
  bool _onlyAvailable = false;
  final _searchCtrl = TextEditingController();
  late Future<QuerySnapshot> _hallsFuture;
  String _userName = 'فرح';

  // ═══════════════════════════════════════════════════════════
  // 🔍 فلاتر البحث المتقدم
  // ═══════════════════════════════════════════════════════════
  String? _searchCity;
  DateTime? _searchDate;
  String? _searchTimeSlot;
  String? _searchEventType;

  // ✅ قائمة النتائج المفلترة (للبحث في الصفحة الرئيسية)
  Future<List<QueryDocumentSnapshot>>? _filteredHallsFuture;
  bool _isAdvancedFiltering = false;
  int _filteredCount = 0;

  static const List<String> _libyanCities = [
    'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'صبراتة', 'الخمس',
    'زليتن', 'سرت', 'سبها', 'درنة', 'طبرق', 'الأبيض',
    'غريان', 'ترهونة', 'بني وليد', 'أجدابيا',
  ];

  static const List<String> _timeSlotsList = [
    'الفترة الصباحية',
    'الفترة العصرية',
    'الفترة المسائية',
  ];

  static const List<String> _eventTypesList = [
    'حفل زفاف', 'محضر', 'عقد قران', 'أسبوع', 'حفل تخرج', 'فضانية',
  ];

  final PageController _bannersCtrl = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _categoriesList = const [
    {'name': 'فساتين', 'image': 'assets/icons/dress.png', 'color': Color(0xFFF48FB1)},
    {'name': 'تجميل', 'image': 'assets/icons/cosmetic-factory.png', 'color': Color(0xFFEC407A)},
    {'name': 'ضيافة', 'image': 'assets/icons/food-tray.png', 'color': Color(0xFFBA68C8)},
    {'name': 'ديكور', 'image': 'assets/icons/wedding-arch.png', 'color': Color(0xFF9C27B0)},
    {'name': 'متاجر', 'image': 'assets/icons/shop.png', 'color': Color(0xFFC2185B)},
  ];

  final List<String> _cities = const ['الكل', 'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'سبها'];

  @override
  void initState() {
    super.initState();
    _hallsFuture = FirebaseFirestore.instance.collection('halls').get();
    _loadUserName();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      if (_bannersCtrl.hasClients) {
        final next = (_currentBanner + 1) % 3;
        _bannersCtrl.animateToPage(next,
            duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['fullName'] ?? data['name'] ?? data['phone'] ?? 'فرح';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bannersCtrl.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHome(),
            const ExploreScreen(),
            const FavoritesScreen(),
            const MyBookingsScreen(),
            const SimpleProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildAdvancedSearchBar()),
        if (_isAdvancedFiltering) SliverToBoxAdapter(child: _buildActiveFiltersBanner()),
        if (!_isAdvancedFiltering) SliverToBoxAdapter(child: _buildHeroBannersCarousel()),
        if (!_isAdvancedFiltering) SliverToBoxAdapter(child: _buildCategoryIcons()),
        SliverToBoxAdapter(child: _buildFeaturedTitle()),
        // ✅ عرض النتائج (مفلترة أو كل القاعات)
        if (_isAdvancedFiltering)
          _buildFilteredHallsSection()
        else
          SliverToBoxAdapter(child: _buildHallsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          _iconButton(Icons.account_balance_wallet_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
          }),
          const SizedBox(width: 8),
          _iconButton(Icons.notifications_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          const Spacer(),
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [primary, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('ف', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('مساء الخير 👋', style: TextStyle(color: textLight, fontSize: 11)),
              const SizedBox(height: 2),
              Text(_userName,
                  style: const TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    if (icon == Icons.notifications_outlined) return _notificationButton(onTap);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
        ),
        child: Icon(icon, color: primary, size: 22),
      ),
    );
  }

  Widget _notificationButton(VoidCallback onTap) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
          ),
          child: const Icon(Icons.notifications_outlined, color: primary, size: 22),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
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
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  // ═══════════════════════════════════════════════════════════
  // 🔍 شريط البحث المتطور
  // ═══════════════════════════════════════════════════════════
  Widget _buildAdvancedSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSearchField(icon: Icons.location_city_outlined, label: 'المدينة', value: _searchCity, onTap: _pickSearchCity)),
                const SizedBox(width: 8),
                Expanded(child: _buildSearchField(
                  icon: Icons.calendar_today_outlined, label: 'التاريخ',
                  value: _searchDate != null ? '${_searchDate!.day}/${_searchDate!.month}/${_searchDate!.year}' : null,
                  onTap: _pickSearchDate,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSearchField(icon: Icons.access_time, label: 'الفترة', value: _searchTimeSlot, onTap: _pickSearchTimeSlot)),
                const SizedBox(width: 8),
                Expanded(child: _buildSearchField(icon: Icons.celebration_outlined, label: 'نوع المناسبة', value: _searchEventType, onTap: _pickSearchEventType)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_isAdvancedFiltering || _searchCity != null || _searchDate != null || _searchTimeSlot != null || _searchEventType != null)
                  GestureDetector(
                    onTap: _clearSearchFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    ),
                  ),
                if (_isAdvancedFiltering || _searchCity != null || _searchDate != null || _searchTimeSlot != null || _searchEventType != null)
                  const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _performAdvancedSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primary, primaryDark]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('ابحث عن قاعة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({required IconData icon, required String label, required String? value, required VoidCallback onTap}) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue ? primary.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasValue ? primary.withValues(alpha: 0.4) : Colors.transparent, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? value : label,
                style: TextStyle(color: hasValue ? textDark : textLight, fontSize: 12, fontWeight: hasValue ? FontWeight.bold : FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: textLight, size: 14),
          ],
        ),
      ),
    );
  }

  void _pickSearchCity() => _showPickerSheet(
    title: 'اختر المدينة', items: _libyanCities, selectedItem: _searchCity, icons: null,
    onSelect: (val) => setState(() => _searchCity = val),
  );

  Future<void> _pickSearchDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context, initialDate: _searchDate ?? now, firstDate: now, lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _searchDate = picked);
  }

  void _pickSearchTimeSlot() => _showPickerSheet(
    title: 'اختر الفترة الزمنية', items: _timeSlotsList, selectedItem: _searchTimeSlot,
    icons: {
      'الفترة الصباحية': Icons.wb_sunny_outlined,
      'الفترة العصرية': Icons.wb_twilight_outlined,
      'الفترة المسائية': Icons.nightlight_round_outlined,
    },
    onSelect: (val) => setState(() => _searchTimeSlot = val),
  );

  void _pickSearchEventType() => _showPickerSheet(
    title: 'اختر نوع المناسبة', items: _eventTypesList, selectedItem: _searchEventType,
    icons: {
      'حفل زفاف': Icons.favorite, 'محضر': Icons.home_outlined,
      'عقد قران': Icons.auto_stories_outlined, 'أسبوع': Icons.child_care_outlined,
      'حفل تخرج': Icons.school_outlined, 'فضانية': Icons.diamond_outlined,
    },
    onSelect: (val) => setState(() => _searchEventType = val),
  );

  void _showPickerSheet({required String title, required List<String> items, required String? selectedItem, required Map<String, IconData>? icons, required Function(String) onSelect}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    final isSelected = selectedItem == item;
                    final itemIcon = icons?[item];
                    return ListTile(
                      leading: itemIcon != null ? Icon(itemIcon, color: isSelected ? primary : textLight, size: 22) : null,
                      title: Text(item, style: TextStyle(color: isSelected ? primary : textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check, color: primary) : null,
                      onTap: () { onSelect(item); Navigator.pop(context); },
                    );
                  }).toList(),
                ),
              ),
            ),
            if (selectedItem != null)
              TextButton.icon(
                onPressed: () { onSelect(''); Navigator.pop(context); },
                icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                label: const Text('مسح الاختيار', style: TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
      ),
    );
  }

  void _clearSearchFilters() {
    setState(() {
      _searchCity = null;
      _searchDate = null;
      _searchTimeSlot = null;
      _searchEventType = null;
      _isAdvancedFiltering = false;
      _filteredHallsFuture = null;
      _filteredCount = 0;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ البحث المتقدم — يعرض النتائج في الصفحة نفسها
  // ═══════════════════════════════════════════════════════════
  Future<void> _performAdvancedSearch() async {
    if (_searchCity == null && _searchDate == null && _searchTimeSlot == null && _searchEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار فلتر واحد على الأقل'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isAdvancedFiltering = true);

    try {
      // 1. جلب القاعات حسب المدينة
      Query hallQuery = FirebaseFirestore.instance.collection('halls');
      if (_searchCity != null) hallQuery = hallQuery.where('city', isEqualTo: _searchCity);
      final hallsSnap = await hallQuery.get();

      // 2. جلب الحجوزات في التاريخ المختار
      final Set<String> bookedHallIds = {};
      if (_searchDate != null) {
        final startOfDay = DateTime(_searchDate!.year, _searchDate!.month, _searchDate!.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('eventDate', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (final doc in bookingsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';
          if (status == 'cancelled' || status == 'expired') continue;
          if (_searchTimeSlot != null) {
            if (data['timeSlot'] == _searchTimeSlot) bookedHallIds.add(data['hallId'] ?? '');
          } else {
            bookedHallIds.add(data['hallId'] ?? '');
          }
        }
      }

      // 3. استثناء القاعات المحجوزة
      var filteredHalls = hallsSnap.docs.where((doc) => !bookedHallIds.contains(doc.id)).toList();

      // 4. فلترة حسب نوع المناسبة
      if (_searchEventType != null) {
        filteredHalls = filteredHalls.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventTypes = data['eventTypes'];
          if (eventTypes is List && eventTypes.isNotEmpty) return eventTypes.contains(_searchEventType);
          return true;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredHallsFuture = Future.value(filteredHalls);
          _filteredCount = filteredHalls.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _filteredHallsFuture = Future.value([]); _filteredCount = 0; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── بانر الفلاتر النشطة ──
  Widget _buildActiveFiltersBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: primary, size: 18),
              const SizedBox(width: 8),
              Text('تم العثور على $_filteredCount قاعة',
                  style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _clearSearchFilters,
                child: const Text('إلغاء',
                    style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              if (_searchCity != null) _buildFilterTag(Icons.location_city_outlined, _searchCity!),
              if (_searchDate != null) _buildFilterTag(Icons.calendar_today_outlined, '${_searchDate!.day}/${_searchDate!.month}'),
              if (_searchTimeSlot != null) _buildFilterTag(Icons.access_time, _searchTimeSlot!),
              if (_searchEventType != null) _buildFilterTag(Icons.celebration_outlined, _searchEventType!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── قسم عرض النتائج المفلترة ──
  Widget _buildFilteredHallsSection() {
    if (_filteredHallsFuture == null) return const SliverToBoxAdapter(child: SizedBox());
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _filteredHallsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: primary))),
          );
        }

        final docs = snap.data ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 70, color: primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 14),
                  const Text('لا توجد قاعات متاحة', style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('جرب تغيير الفلاتر', style: TextStyle(color: textLight, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                data['_id'] = docs[i].id;
                // ✅ تمرير الفلاتر إلى شاشة التفاصيل
                data['_prefilledDate'] = _searchDate;
                data['_prefilledEventType'] = _searchEventType;
                data['_prefilledTimeSlot'] = _searchTimeSlot;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildHallVerticalCard(data, prefilled: true),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBannersCarousel() {
    final banners = [
      {'title': 'ليلة العمر تبدأ من هنا', 'desc': 'اكتشف أرقى قاعات الأفراح في ليبيا واحجزها بضغطة واحدة.', 'btn': 'تصفّح القاعات'},
      {'title': 'عروض موسمية', 'desc': 'خصومات تصل إلى 30% على القاعات المميزة - لفترة محدودة.', 'btn': 'اكتشف العروض'},
      {'title': 'نصائح لتخطيط حفلك', 'desc': 'احجز مبكراً، قارن بين القاعات، واطلب صوراً حقيقية.', 'btn': 'اقرأ النصائح'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      height: 175,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannersCtrl,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: banners.length,
            itemBuilder: (context, i) {
              final b = banners[i];
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    Positioned(top: -40, left: -40, child: Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)))),
                    Positioned(bottom: -60, right: -40, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)))),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(b['title']!, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(b['desc']!, textAlign: TextAlign.right, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.5)),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(b['btn']!, style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_back_ios, color: primary, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                final active = i == _currentBanner;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _categoriesList.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final cat = _categoriesList[i];
            final color = cat['color'] as Color;
            
            return GestureDetector(
              onTap: () {
                // ✅ تم ربط التصنيفات بشاشة المتاجر هنا
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoresListScreen()),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 66, height: 66,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                    ),
                    child: Image.asset(cat['image'] as String, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: color, size: 28)),
                  ),
                  const SizedBox(height: 8),
                  Text(cat['name'] as String, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          if (!_isAdvancedFiltering)
            GestureDetector(
              onTap: () => setState(() => _isGrid = !_isGrid),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
                ),
                child: Icon(_isGrid ? Icons.view_list : Icons.grid_view, color: primary, size: 18),
              ),
            ),
          const Spacer(),
          Text(
            _isAdvancedFiltering ? 'نتائج البحث' : 'قاعات مميزة',
            style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHallsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: _hallsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: primary)));
        }
        if (snapshot.hasError) return _buildEmpty();

        final allDocs = snapshot.data?.docs ?? [];
        if (allDocs.isEmpty) return _buildEmpty();

        final query = _searchCtrl.text.trim();
        final docs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final price = (d['price'] ?? 0) is int ? (d['price'] as int).toDouble() : double.tryParse(d['price'].toString()) ?? 0;
          final rating = (d['rating'] ?? 0).toDouble();
          final city = (d['city'] ?? '').toString();
          final name = (d['name'] ?? '').toString();
          final type = (d['type'] ?? '').toString();
          final isAvailable = d['isAvailable'] ?? true;

          if (query.isNotEmpty && !name.contains(query) && !city.contains(query)) return false;
          if (price < _priceRange.start || price > _priceRange.end) return false;
          if (rating < _minRating) return false;
          if (_selectedCity != 'الكل' && city != _selectedCity) return false;
          if (_selectedType != 'الكل' && type != _selectedType) return false;
          if (_onlyAvailable && isAvailable == false) return false;
          return true;
        }).toList();

        if (docs.isEmpty) return _buildEmpty();

        if (_isGrid) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                data['_id'] = docs[i].id;
                return _buildHallGridCard(data);
              },
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['_id'] = doc.id;
              return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildHallVerticalCard(data, prefilled: false));
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _favoriteButton(Map<String, dynamic> hall) {
    final id = hall['_id'] as String? ?? hall['id'] as String? ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final favs = List<String>.from(data?['favorites'] ?? []);
        final isFav = favs.contains(id);
        return GestureDetector(
          onTap: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            if (isFav) {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'favorites': FieldValue.arrayRemove([id])});
            } else {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'favorites': FieldValue.arrayUnion([id])});
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isFav ? 'تم الإزالة من المفضلة' : 'تمت الإضافة للمفضلة'), duration: const Duration(seconds: 1)),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)]),
            child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 20),
          ),
        );
      },
    );
  }

  // ✅ بطاقة القاعة العمودية — تدعم تمرير الفلاتر
  Widget _buildHallVerticalCard(Map<String, dynamic> hall, {bool prefilled = false}) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HallDetailsScreen(
            hallData: hall,
            prefilledDate: prefilled ? _searchDate : null,
            prefilledEventType: prefilled ? _searchEventType : null,
            prefilledTimeSlot: prefilled ? _searchTimeSlot : null,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 170, width: double.infinity,
                    // ✅ استخدام CachedNetworkImage
                    child: image != null
                        ? CachedNetworkImage(
                            imageUrl: image.toString(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: primary.withValues(alpha: 0.1),
                              child: const Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.celebration, color: Colors.white, size: 50),
                            ),
                          )
                        : Container(color: primary.withValues(alpha: 0.2), child: const Icon(Icons.celebration, color: Colors.white, size: 50)),
                  ),
                  Positioned(top: 12, right: 12, child: _favoriteButton(hall)),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Text('مميزة', style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('$price د.ل', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(city, style: const TextStyle(color: textLight, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHallGridCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110, width: double.infinity,
                    // ✅ استخدام CachedNetworkImage
                    child: image != null
                        ? CachedNetworkImage(
                            imageUrl: image.toString(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: primary.withValues(alpha: 0.1),
                              child: const Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                            ),
                          )
                        : Container(color: primary.withValues(alpha: 0.2), child: const Icon(Icons.celebration, color: Colors.white, size: 40)),
                  ),
                  Positioned(top: 8, right: 8, child: _favoriteButton(hall)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: textLight, size: 11),
                    const SizedBox(width: 2),
                    Expanded(child: Text(city, style: const TextStyle(color: textLight, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price', style: const TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 11),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(color: textDark, fontSize: 10, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 70, color: primary.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          const Text('لا توجد قاعات', style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.explore_outlined, 'active': Icons.explore, 'label': 'استكشف'},
      {'icon': Icons.favorite_border, 'active': Icons.favorite, 'label': 'المفضلة'},
      {'icon': Icons.event_note_outlined, 'active': Icons.event_note, 'label': 'حجوزاتي'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'حسابي'},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 25, offset: const Offset(0, 8))]),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final active = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
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
                  Icon(active ? items[i]['active'] as IconData : items[i]['icon'] as IconData, color: active ? Colors.white : textLight, size: 20),
                  if (active) ...[
                    const SizedBox(width: 5),
                    Text(items[i]['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// شاشة الملف الشخصي المبسطة (للزبون)
// ═══════════════════════════════════════════════
class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});
  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _userFuture = uid == null ? Future.error('no user') : FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text('تسجيل الخروج', textAlign: TextAlign.right, style: TextStyle(color: textDark)),
        content: const Text('هل أنت متأكد؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const FarahGlassLoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('تعذر تحميل البيانات'));
        final user = snap.data!.data() as Map<String, dynamic>;
        final name = user['fullName'] ?? 'مستخدم';
        final phone = user['phone'] ?? '';
        final role = user['role'] ?? 'user';
        final isProvider = role == 'provider';

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 110, height: 110,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primary, primaryDark])),
                child: Icon(isProvider ? Icons.storefront : Icons.person, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [primary, primaryDark]), borderRadius: BorderRadius.circular(20)),
                child: Text(isProvider ? 'مزوّد خدمة' : 'زبون', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: _infoRow(Icons.phone_outlined, 'رقم الهاتف', phone.isEmpty ? 'غير محدد' : phone),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    if (isProvider) ...[
                      _menuItem(Icons.dashboard_outlined, 'لوحة المزود', 'إدارة حجوزاتك وأرباحك', () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()));
                      }),
                      const SizedBox(height: 10),
                    ],
                    _menuItem(Icons.calendar_month, 'حجوزاتي', 'سجل حجوزاتك السابقة والقادمة', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.favorite_border, 'المفضلة', 'القاعات المحفوظة', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.account_balance_wallet, 'محفظتي', 'رصيدك وطرق الدفع', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                    }),
                    const SizedBox(height: 10),
                    _menuItem(Icons.notifications_outlined, 'الإشعارات', 'تخصيص التنبيهات', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    }),
                    const SizedBox(height: 10),
                    _menuItem(Icons.edit_outlined, 'تعديل الملف الشخصي', 'الاسم وكلمة المرور', () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      if (result == true && mounted) {
                        setState(() {
                          _userFuture = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
                        });
                      }
                    }),
                    const SizedBox(height: 10),
                    _menuItem(Icons.settings_outlined, 'الإعدادات', 'اللغة والمظهر والخصوصية', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.help_outline, 'المساعدة والدعم', 'تواصل معنا', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.info_outline, 'عن التطبيق', 'فرح — الإصدار 1.0.0', () {}),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: _logout,
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1.2),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('فرح — الإصدار 1.0.0', style: TextStyle(color: textLight, fontSize: 11)),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [primary, primaryDark]), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: textLight, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary.withValues(alpha: 0.9), primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: textLight, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, color: textLight, size: 14),
          ],
        ),
      ),
    );
  }
}
