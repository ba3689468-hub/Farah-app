import 'dart:async';
import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/screens/login_screen_farah.dart';
import 'features/favorites_screen.dart';
import 'features/explore_screen.dart';
import 'features/edit_profile_screen.dart';
import 'features/wallet_screen.dart';
import 'features/notifications_screen.dart';
import 'features/provider_dashboard_screen.dart';
import 'hall_details_screen.dart';
import 'my_bookings_screen.dart';

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
        SliverToBoxAdapter(child: _buildSearchBar()),
        SliverToBoxAdapter(child: _buildHeroBannersCarousel()),
        SliverToBoxAdapter(child: _buildCategoryIcons()),
        SliverToBoxAdapter(child: _buildFeaturedTitle()),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          }),
          const SizedBox(width: 8),
          _iconButton(Icons.notifications_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          }, hasBadge: false),
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

  Widget _iconButton(IconData icon, VoidCallback onTap, {bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          if (hasBadge)
            Positioned(
              top: 8, right: 8,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: primary.withValues(alpha: 0.1), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textAlign: TextAlign.right,
                      onChanged: (v) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن قاعة أو مدينة...',
                        hintStyle: TextStyle(color: textLight, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.tune, color: Colors.white, size: 22)),
                  if (_minRating > 0 || _priceRange.start > 0 || _priceRange.end < 50000 || _onlyAvailable || _selectedType != 'الكل' || _selectedCity != 'الكل')
                    Positioned(
                      top: 10, right: 10,
                      child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                  width: active ? 20 : 6,
                  height: 6,
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
            return Column(
              children: [
                Container(
                  width: 66, height: 66,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                  ),
                  child: Image.asset(
                    cat['image'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Text(cat['name'] as String, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
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
          const Text('قاعات مميزة', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
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
              return Padding(padding: const EdgeInsets.only(bottom: 14), child: _buildHallVerticalCard(data));
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _favoriteButton(Map<String, dynamic> hall) {
    final id = hall['_id'] as String? ?? hall['id'] as String? ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final favs = List<String>.from(data?['favorites'] ?? []);
        final isFav = favs.contains(id);
        return GestureDetector(
          onTap: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;
            if (isFav) {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'favorites': FieldValue.arrayRemove([id]),
              });
            } else {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                'favorites': FieldValue.arrayUnion([id]),
              });
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav ? 'تم الإزالة من المفضلة' : 'تمت الإضافة للمفضلة'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
              ],
            ),
            child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildHallVerticalCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall))),
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
                    child: image != null
                        ? Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: primary.withValues(alpha: 0.2), child: const Icon(Icons.celebration, color: Colors.white, size: 50)))
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
                      Expanded(
                        child: Text(name, style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110, width: double.infinity,
                    child: image != null
                        ? Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: primary.withValues(alpha: 0.2), child: const Icon(Icons.celebration, color: Colors.white, size: 40)))
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Row(
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        RangeValues tempRange = _priceRange;
        double tempRating = _minRating;
        String tempType = _selectedType;
        String tempCity = _selectedCity;
        bool tempAvail = _onlyAvailable;

        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('الفلترة', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setSheet(() {
                            tempRange = const RangeValues(0, 50000);
                            tempRating = 0;
                            tempType = 'الكل';
                            tempCity = 'الكل';
                            tempAvail = false;
                          });
                        },
                        child: const Text('إعادة تعيين', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('المدينة', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _cities.map((city) {
                      final active = city == tempCity;
                      return GestureDetector(
                        onTap: () => setSheet(() => tempCity = city),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                            color: active ? null : AppColors.softBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? Colors.transparent : primary.withValues(alpha: 0.15)),
                          ),
                          child: Text(city, style: TextStyle(color: active ? Colors.white : textDark, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text('نطاق السعر (د.ل)', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: tempRange, min: 0, max: 50000, divisions: 50,
                    activeColor: primary,
                    inactiveColor: primary.withValues(alpha: 0.15),
                    labels: RangeLabels('${tempRange.start.round()}', '${tempRange.end.round()}'),
                    onChanged: (v) => setSheet(() => tempRange = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('التقييم', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < tempRating.round();
                      return GestureDetector(
                        onTap: () => setSheet(() => tempRating = (i + 1).toDouble()),
                        child: Padding(padding: const EdgeInsets.only(right: 6), child: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber, size: 30)),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  const Text('نوع القاعة', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['الكل', 'قاعات أفراح', 'قاعات مؤتمرات', 'استراحات'].map((t) {
                      final active = t == tempType;
                      return GestureDetector(
                        onTap: () => setSheet(() => tempType = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                            color: active ? null : AppColors.softBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t, style: TextStyle(color: active ? Colors.white : textDark, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Switch(value: tempAvail, activeColor: primary, onChanged: (v) => setSheet(() => tempAvail = v)),
                      const SizedBox(width: 8),
                      const Text('متاح الآن فقط', style: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _priceRange = tempRange;
                          _minRating = tempRating;
                          _selectedType = tempType;
                          _selectedCity = tempCity;
                          _onlyAvailable = tempAvail;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('تطبيق الفلترة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// شاشة الملف الشخصي المبسطة
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FarahGlassLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primary));
        }
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('تعذر تحميل البيانات'));
        }
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [primary, primaryDark]),
                ),
                child: Icon(isProvider ? Icons.storefront : Icons.person, size: 55, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isProvider ? 'مزوّد خدمة' : 'زبون',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      _infoRow(Icons.phone_outlined, 'رقم الهاتف', phone.isEmpty ? 'غير محدد' : phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ✅ لوحة المزود (تظهر فقط للمزودين)
                    if (isProvider) ...[
                      _menuItem(Icons.dashboard_outlined, 'لوحة المزود',
                          'إدارة حجوزاتك وأرباحك', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProviderDashboardScreen()),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    _menuItem(Icons.calendar_month, 'حجوزاتي', 'سجل حجوزاتك السابقة والقادمة', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.favorite_border, 'المفضلة', 'القاعات المحفوظة', () {}),
                    const SizedBox(height: 10),
                    _menuItem(Icons.account_balance_wallet, 'محفظتي', 'رصيدك وطرق الدفع', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
                    }),
                    const SizedBox(height: 10),
                    _menuItem(Icons.notifications_outlined, 'الإشعارات', 'تخصيص التنبيهات', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    }),
                    const SizedBox(height: 10),
                    _menuItem(Icons.edit_outlined, 'تعديل الملف الشخصي', 'الاسم وكلمة المرور', () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                      if (result == true && mounted) {
                        setState(() {
                          _userFuture = FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .get();
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
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primary, primaryDark]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
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
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withValues(alpha: 0.9), primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
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
