import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../hall_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  // ✅ استقبال الفلاتر من الصفحة الرئيسية
  final String? initialCity;
  final DateTime? initialDate;
  final String? initialTimeSlot;
  final String? initialEventType;

  const ExploreScreen({
    super.key,
    this.initialCity,
    this.initialDate,
    this.initialTimeSlot,
    this.initialEventType,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  late Future<List<QueryDocumentSnapshot>> _hallsFuture;
  String _selectedFilter = 'الأكثر رواجاً';

  // ── فلاتر قادمة من الصفحة الرئيسية ──
  String? _activeCity;
  DateTime? _activeDate;
  String? _activeTimeSlot;
  String? _activeEventType;

  bool _isFiltered = false;

  final List<Map<String, dynamic>> _filters = [
    {'name': 'الأكثر رواجاً', 'icon': Icons.local_fire_department},
    {'name': 'الأعلى تقييماً', 'icon': Icons.star},
    {'name': 'الجديد', 'icon': Icons.new_releases},
    {'name': 'الأقل سعراً', 'icon': Icons.attach_money},
  ];

  @override
  void initState() {
    super.initState();
    _activeCity = widget.initialCity;
    _activeDate = widget.initialDate;
    _activeTimeSlot = widget.initialTimeSlot;
    _activeEventType = widget.initialEventType;

    if (_activeCity != null ||
        _activeDate != null ||
        _activeTimeSlot != null ||
        _activeEventType != null) {
      _performFilteredSearch();
    } else {
      _loadAllHalls();
    }
  }

  Future<void> _loadAllHalls() async {
    final snap = await FirebaseFirestore.instance.collection('halls').get();
    if (mounted) {
      setState(() {
        _hallsFuture = Future.value(snap.docs);
        _isFiltered = false;
      });
    }
  }

  Future<void> _performFilteredSearch() async {
    try {
      Query hallQuery = FirebaseFirestore.instance.collection('halls');
      if (_activeCity != null) {
        hallQuery = hallQuery.where('city', isEqualTo: _activeCity);
      }
      final hallsSnap = await hallQuery.get();

      final Set<String> bookedHallIds = {};

      if (_activeDate != null) {
        final startOfDay = DateTime(_activeDate!.year, _activeDate!.month, _activeDate!.day);
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

          if (_activeTimeSlot != null) {
            if (data['timeSlot'] == _activeTimeSlot) {
              bookedHallIds.add(data['hallId'] ?? '');
            }
          } else {
            bookedHallIds.add(data['hallId'] ?? '');
          }
        }
      }

      var filteredHalls = hallsSnap.docs
          .where((doc) => !bookedHallIds.contains(doc.id))
          .toList();

      if (_activeEventType != null) {
        filteredHalls = filteredHalls.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final eventTypes = data['eventTypes'];
          if (eventTypes is List && eventTypes.isNotEmpty) {
            return eventTypes.contains(_activeEventType);
          }
          return true;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _hallsFuture = Future.value(filteredHalls);
          _isFiltered = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hallsFuture = Future.value([]);
          _isFiltered = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _activeCity = null;
      _activeDate = null;
      _activeTimeSlot = null;
      _activeEventType = null;
    });
    _loadAllHalls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _hallsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primary));
            }

            final docs = snap.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (_isFiltered)
                  SliverToBoxAdapter(child: _buildActiveFiltersBanner(docs.length)),
                SliverToBoxAdapter(child: _buildFilterChips()),
                ..._buildSections(docs),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
              Text(
                'تم العثور على $count قاعة',
                style: const TextStyle(
                    color: textDark, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearFilters,
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (_activeCity != null) _buildFilterTag(Icons.location_city_outlined, _activeCity!),
              if (_activeDate != null)
                _buildFilterTag(
                    Icons.calendar_today_outlined,
                    '${_activeDate!.day}/${_activeDate!.month}'),
              if (_activeTimeSlot != null) _buildFilterTag(Icons.access_time, _activeTimeSlot!),
              if (_activeEventType != null)
                _buildFilterTag(Icons.celebration_outlined, _activeEventType!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: textDark, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

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
          GestureDetector(
            onTap: _loadAllHalls,
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
            child: const Icon(Icons.explore, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: 200,
                    child: image != null
                        ? Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: primary.withValues(alpha: 0.2),
                              child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                            ))
                        : Container(
                            color: primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                          ),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
                      ),
                      child: Center(
                        child: Text('#$rank',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
                  Text(name,
                      style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: textLight, size: 12),
                    const SizedBox(width: 3),
                    Expanded(child: Text(city, style: const TextStyle(color: textLight, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price د.ل', style: const TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
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
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: SizedBox(
                width: 100, height: 100,
                child: image != null
                    ? Image.network(image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.celebration, color: Colors.white, size: 30),
                        ))
                    : Container(
                        color: primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.celebration, color: Colors.white, size: 30),
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
                    Text(name,
                        style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(city, style: const TextStyle(color: textLight, fontSize: 11)),
                        const SizedBox(width: 3),
                        const Icon(Icons.location_on_outlined, color: textLight, size: 12),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$price د.ل', style: const TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 70, color: primary.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text(
            _isFiltered ? 'لا توجد قاعات متاحة' : 'لا توجد قاعات',
            style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (_isFiltered) ...[
            const SizedBox(height: 8),
            const Text('جرب تغيير الفلاتر', style: TextStyle(color: textLight, fontSize: 12)),
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
