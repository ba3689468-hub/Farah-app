import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../hall_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  // ── قائمة المدن الليبية ──
  static const List<String> _libyanCities = [
    'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'صبراتة', 'الخمس',
    'زليتن', 'سرت', 'سبها', 'درنة', 'طبرق', 'الأبيض',
    'غريان', 'ترهونة', 'بني وليد', 'أجدابيا', 'مرزق', 'أوباري',
  ];

  // ── الفترات الزمنية ──
  static const List<String> _timeSlots = [
    'الفترة الصباحية',
    'الفترة العصرية',
    'الفترة المسائية',
  ];

  late Future<List<QueryDocumentSnapshot>> _hallsFuture;
  String _selectedFilter = 'الأكثر رواجاً';

  // ── فلاتر البحث (منع التسرب) ──
  String? _selectedCity;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  bool _isSearching = false;
  bool _loading = false;

  final List<Map<String, dynamic>> _filters = [
    {'name': 'الأكثر رواجاً', 'icon': Icons.local_fire_department},
    {'name': 'الأعلى تقييماً', 'icon': Icons.star},
    {'name': 'الجديد', 'icon': Icons.new_releases},
    {'name': 'الأقل سعراً', 'icon': Icons.attach_money},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllHalls();
  }

  Future<void> _loadAllHalls() async {
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance.collection('halls').get();
    if (mounted) {
      setState(() {
        _hallsFuture = Future.value(snap.docs);
        _loading = false;
        _isSearching = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔍 البحث المفلتر (منع التسرب)
  // ═══════════════════════════════════════════════════════════
  Future<void> _searchHalls() async {
    if (_selectedCity == null && _selectedDate == null && _selectedTimeSlot == null) {
      _showSnack('الرجاء اختيار فلتر واحد على الأقل', Colors.orange);
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. جلب القاعات في المدينة المختارة
      Query hallQuery = FirebaseFirestore.instance.collection('halls');
      if (_selectedCity != null) {
        hallQuery = hallQuery.where('city', isEqualTo: _selectedCity);
      }
      final hallsSnap = await hallQuery.get();

      // 2. جلب الحجوزات في التاريخ المختار
      final Set<String> bookedHallIds = {};

      if (_selectedDate != null) {
        final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('eventDate', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

        for (final doc in bookingsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';

          // نتجاهل الحجوزات الملغية والمنتهية
          if (status == 'cancelled' || status == 'expired') continue;

          // إذا تم اختيار فترة، نفلتر بها
          if (_selectedTimeSlot != null) {
            if (data['timeSlot'] == _selectedTimeSlot) {
              bookedHallIds.add(data['hallId'] ?? '');
            }
          } else {
            bookedHallIds.add(data['hallId'] ?? '');
          }
        }
      }

      // 3. استثناء القاعات المحجوزة
      final filteredHalls = hallsSnap.docs
          .where((doc) => !bookedHallIds.contains(doc.id))
          .toList();

      if (mounted) {
        setState(() {
          _hallsFuture = Future.value(filteredHalls);
          _loading = false;
          _isSearching = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('حدث خطأ أثناء البحث: $e', Colors.red);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedDate = null;
      _selectedTimeSlot = null;
    });
    _loadAllHalls();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _hallsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting || _loading) {
              return const Center(child: CircularProgressIndicator(color: primary));
            }

            final docs = snap.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildFilterChips()),
                if (_isSearching)
                  SliverToBoxAdapter(child: _buildSearchBanner(docs.length)),
                ..._buildSections(docs),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 🔍 شريط البحث الجديد (منع التسرب)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildCitySelector()),
                const SizedBox(width: 8),
                Expanded(child: _buildDateSelector()),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTimeSlotSelector()),
                const SizedBox(width: 8),
                _buildSearchButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return GestureDetector(
      onTap: _showCityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedCity != null
              ? primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCity != null ? primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_city_outlined, color: primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedCity ?? 'المدينة',
                style: TextStyle(
                  color: _selectedCity != null ? textDark : textLight,
                  fontSize: 12,
                  fontWeight: _selectedCity != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedDate != null
              ? primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedDate != null ? primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'التاريخ',
                style: TextStyle(
                  color: _selectedDate != null ? textDark : textLight,
                  fontSize: 12,
                  fontWeight: _selectedDate != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    return GestureDetector(
      onTap: _showTimeSlotPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _selectedTimeSlot != null
              ? primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedTimeSlot != null ? primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedTimeSlot ?? 'الفترة الزمنية',
                style: TextStyle(
                  color: _selectedTimeSlot != null ? textDark : textLight,
                  fontSize: 12,
                  fontWeight: _selectedTimeSlot != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final hasFilters = _selectedCity != null ||
        _selectedDate != null ||
        _selectedTimeSlot != null;
    return Row(
      children: [
        if (hasFilters) ...[
          GestureDetector(
            onTap: _clearFilters,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: _searchHalls,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text('بحث',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBanner(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_alt, color: primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم العثور على $count قاعة متاحة',
                style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: _clearFilters,
              child: const Text(
                'إلغاء الفلترة',
                style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── اختيار المدينة ──
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اختر المدينة',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _libyanCities.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.location_on_outlined,
                        color: primary, size: 20),
                    title: Text(_libyanCities[i],
                        style: const TextStyle(color: textDark)),
                    trailing: _selectedCity == _libyanCities[i]
                        ? const Icon(Icons.check, color: primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedCity = _libyanCities[i]);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── اختيار التاريخ ──
  void _showDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── اختيار الفترة ──
  void _showTimeSlotPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('اختر الفترة الزمنية',
                style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              final icons = {
                'الفترة الصباحية': Icons.wb_sunny_outlined,
                'الفترة العصرية': Icons.wb_twilight_outlined,
                'الفترة المسائية': Icons.nightlight_round_outlined,
              };
              return ListTile(
                leading: Icon(icons[slot] ?? Icons.access_time,
                    color: isSelected ? primary : textLight),
                title: Text(slot,
                    style: TextStyle(
                        color: isSelected ? primary : textDark,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: primary)
                    : null,
                onTap: () {
                  setState(() => _selectedTimeSlot = slot);
                  Navigator.pop(context);
                },
              );
            }),
          ],
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
            'استكشف',
            style: TextStyle(
              color: textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ── شرائح الفلترة ──
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final active = f['name'] == _selectedFilter;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = f['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(colors: [primary, primaryDark])
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
                    Icon(f['icon'] as IconData,
                        color: active ? Colors.white : primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      f['name'] as String,
                      style: TextStyle(
                        color: active ? Colors.white : textDark,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── بناء الأقسام ──
  List<Widget> _buildSections(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return [
        SliverToBoxAdapter(child: _buildEmpty()),
      ];
    }

    final sortedDocs = List<QueryDocumentSnapshot>.from(docs);

    switch (_selectedFilter) {
      case 'الأعلى تقييماً':
        sortedDocs.sort((a, b) {
          final aR = (a.data() as Map)['rating'] ?? 0;
          final bR = (b.data() as Map)['rating'] ?? 0;
          return (bR as num).compareTo(aR as num);
        });
        break;
      case 'الجديد':
        sortedDocs.sort((a, b) {
          final aT = (a.data() as Map)['createdAt'] as Timestamp?;
          final bT = (b.data() as Map)['createdAt'] as Timestamp?;
          if (aT == null && bT == null) return 0;
          if (aT == null) return 1;
          if (bT == null) return -1;
          return bT.compareTo(aT);
        });
        break;
      case 'الأقل سعراً':
        sortedDocs.sort((a, b) {
          final aP = (a.data() as Map)['price'] ?? 0;
          final bP = (b.data() as Map)['price'] ?? 0;
          return (aP as num).compareTo(bP as num);
        });
        break;
      case 'الأكثر رواجاً':
      default:
        sortedDocs.sort((a, b) {
          final aB = (a.data() as Map)['bookingsCount'] ?? 0;
          final bB = (b.data() as Map)['bookingsCount'] ?? 0;
          if ((aB as num) == 0 && (bB as num) == 0) {
            final aR = (a.data() as Map)['rating'] ?? 0;
            final bR = (b.data() as Map)['rating'] ?? 0;
            return (bR as num).compareTo(aR as num);
          }
          return (bB).compareTo(aB);
        });
        break;
    }

    final topThree = sortedDocs.take(3).toList();
    final rest = sortedDocs.skip(3).toList();

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(
            children: [
              Text(
                _selectedFilter,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sortedDocs.length}',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (topThree.isNotEmpty)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: topThree.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final data = topThree[i].data() as Map<String, dynamic>;
                data['_id'] = topThree[i].id;
                return _buildFeaturedCard(data, i + 1);
              },
            ),
          ),
        ),
      if (rest.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'قاعات أخرى',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final data = rest[i].data() as Map<String, dynamic>;
                data['_id'] = rest[i].id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCompactCard(data),
                );
              },
              childCount: rest.length,
            ),
          ),
        ),
      ],
    ];
  }

  // ── البطاقة المميزة (الأفضل 3) ──
  Widget _buildFeaturedCard(Map<String, dynamic> hall, int rank) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else {
      rankColor = const Color(0xFFCD7F32);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: 200,
                    child: image != null
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.celebration,
                                  color: Colors.white, size: 40),
                            ),
                          )
                        : Container(
                            color: primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.celebration,
                                color: Colors.white, size: 40),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: textLight, size: 12),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          city,
                          style: const TextStyle(
                              color: textLight, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$price د.ل',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  // ── البطاقة المدمجة ──
  Widget _buildCompactCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                height: 100,
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.celebration,
                              color: Colors.white, size: 30),
                        ),
                      )
                    : Container(
                        color: primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.celebration,
                            color: Colors.white, size: 30),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          city,
                          style: const TextStyle(
                              color: textLight, fontSize: 11),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.location_on_outlined,
                            color: textLight, size: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$price د.ل',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  // ── لا توجد قاعات ──
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off,
              size: 70, color: primary.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text(
            _isSearching ? 'لا توجد قاعات متاحة' : 'لا توجد قاعات',
            style: const TextStyle(
                color: textDark, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (_isSearching) ...[
            const SizedBox(height: 8),
            const Text(
              'جرب تغيير التاريخ أو الفترة الزمنية',
              style: TextStyle(color: textLight, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh, color: primary),
              label: const Text('إلغاء الفلترة',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
