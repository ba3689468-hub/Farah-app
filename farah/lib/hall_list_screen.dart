import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/screens/login_screen_farah.dart';
import 'hall_details_screen.dart';
import 'my_bookings_screen.dart';

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});
  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  static const Color primary = Color(0xFFF06292);
  static const Color primaryDark = Color(0xFFEC407A);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF999999);
  static const Color cardWhite = Colors.white;
  static const Color bgStart = Color(0xFFFCE4EC);
  static const Color bgEnd = Color(0xFFFFF5F7);

  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  String _selectedCity = 'الكل';
  late Future<QuerySnapshot> _hallsFuture;

  final List<Map<String, dynamic>> _categoriesList = const [
    {'name': 'فساتين', 'icon': Icons.checkroom, 'color': Color(0xFFF48FB1)},
    {'name': 'تجميل', 'icon': Icons.spa, 'color': Color(0xFFF06292)},
    {'name': 'ضيافة', 'icon': Icons.restaurant_menu, 'color': Color(0xFFBA68C8)},
    {'name': 'ديكور', 'icon': Icons.auto_awesome, 'color': Color(0xFFEC407A)},
    {'name': 'متاجر', 'icon': Icons.storefront, 'color': Color(0xFFC2185B)},
  ];

  final List<String> _cities = const [
    'الكل', 'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'سبها',
  ];

  @override
  void initState() {
    super.initState();
    _hallsFuture = FirebaseFirestore.instance.collection('halls').get();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCE4EC),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHome(),
              const Center(child: Text('استكشف', style: TextStyle(fontSize: 18, color: textDark))),
              const MyBookingsScreen(),
              const SimpleProfileScreen(),
            ],
          ),
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
        SliverToBoxAdapter(child: _buildCityChips()),
        SliverToBoxAdapter(child: _buildHeroBanner()),
        SliverToBoxAdapter(child: _buildCategoryIcons()),
        SliverToBoxAdapter(child: _buildFeaturedTitle()),
        SliverToBoxAdapter(child: _buildHallsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Center(
              child: Text('ف', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('مساء الخير', style: TextStyle(color: textLight, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'فرح',
                style: const TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن قاعة في ليبيا...',
                  hintStyle: TextStyle(color: textLight, fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final city = _cities[i];
          final active = city == _selectedCity;
          return GestureDetector(
            onTap: () => setState(() => _selectedCity = city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active
                  ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Text(city,
                style: TextStyle(
                  color: active ? Colors.white : textDark,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, left: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
          Positioned(
            bottom: -60, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليلة العمر تبدأ من هنا',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('اكتشف أرقى قاعات الأفراح في ليبيا واحجزها بضغطة واحدة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.5)),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('تصفّح القاعات',
                          style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_back_ios, color: primary, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return SizedBox(
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
                    BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 4, offset: const Offset(-2, -2)),
                  ],
                ),
                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(cat['name'] as String,
                style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturedTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isGrid = !_isGrid),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(
                _isGrid ? Icons.view_list : Icons.grid_view,
                color: primary, size: 18,
              ),
            ),
          ),
          const Spacer(),
          const Text('قاعات مميزة',
            style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHallsSection() {
    return FutureBuilder<QuerySnapshot>(
      future: _hallsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: primary)),
          );
        }
        if (snapshot.hasError) return _buildEmpty();

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmpty();

        // عرض أفقي ببطاقات صغيرة
        if (_isGrid) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data = docs[i].data() as Map<String, dynamic>;
                return _buildHallGridCard(data);
              },
            ),
          );
        }
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _buildHallMiniCard(data);
            },
          ),
        );
      },
    );
  }

  Widget _buildHallMiniCard(Map<String, dynamic> hall) {
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
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120, width: 170,
                    child: image != null
                      ? Image.network(image, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: primary.withOpacity(0.2),
                            child: const Icon(Icons.celebration, color: Colors.white, size: 40)))
                      : Container(
                          color: primary.withOpacity(0.2),
                          child: const Icon(Icons.celebration, color: Colors.white, size: 40)),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('مميزة',
                        style: TextStyle(color: primary, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: textLight, size: 11),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(city,
                          style: const TextStyle(color: textLight, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price د.ل',
                        style: const TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(rating.toStringAsFixed(1),
                            style: const TextStyle(color: textDark, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildHallGridCard(Map<String, dynamic> hall) {
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 100, width: double.infinity,
                child: image != null
                    ? Image.network(image, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: primary.withOpacity(0.2),
                          child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                        ))
                    : Container(
                        color: primary.withOpacity(0.2),
                        child: const Icon(Icons.celebration, color: Colors.white, size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: textLight, size: 11),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(city,
                          style: const TextStyle(color: textLight, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price',
                          style: const TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.bold)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 11),
                        Text(rating.toStringAsFixed(1),
                            style: const TextStyle(color: textDark, fontSize: 10, fontWeight: FontWeight.bold)),
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
          Icon(Icons.storefront_outlined, size: 70, color: primary.withOpacity(0.3)),
          const SizedBox(height: 14),
          const Text('لا توجد قاعات',
            style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.explore_outlined, 'active': Icons.explore, 'label': 'استكشف'},
      {'icon': Icons.event_note_outlined, 'active': Icons.event_note, 'label': 'حجوزاتي'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'حسابي'},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final active = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [primary, primaryDark]) : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active ? [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))] : [],
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
                    const SizedBox(width: 6),
                    Text(items[i]['label'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});
  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  static const Color primary = Color(0xFFF06292);
  static const Color primaryDark = Color(0xFFEC407A);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF999999);

  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _userFuture = uid == null
        ? Future.error('no user')
        : FirebaseFirestore.instance.collection('users').doc(uid).get();
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
        final name  = user['fullName'] ?? 'مستخدم';
        final email = user['email'] ?? '';
        final phone = user['phone'] ?? '';
        final role  = user['role'] ?? 'user';
        final isProvider = role == 'provider';

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [primary, primaryDark]),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 25, offset: const Offset(0, 10))],
                ),
                child: Icon(isProvider ? Icons.storefront : Icons.person,
                  size: 55, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name,
                style: const TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Text(isProvider ? 'مزوّد خدمة' : 'زبون',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.email_outlined, 'البريد الإلكتروني', email.isEmpty ? 'غير محدد' : email),
                      const Divider(height: 26, color: Colors.black12),
                      _infoRow(Icons.phone_outlined, 'رقم الهاتف', phone.isEmpty ? 'غير محدد' : phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _tile(Icons.calendar_month, 'حجوزاتي', () {
                      Navigator.pop(context);
                    })),
                    const SizedBox(width: 10),
                    Expanded(child: _tile(Icons.favorite_border, 'المفضلة', () {})),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _tile(Icons.settings_outlined, 'الإعدادات', () {})),
                    const SizedBox(width: 10),
                    Expanded(child: _tile(Icons.help_outline, 'المساعدة', () {})),
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
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.2),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 20),
                          SizedBox(width: 10),
                          Text('تسجيل الخروج',
                            style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('فرح — الإصدار 1.0.0',
                style: TextStyle(color: textLight, fontSize: 11)),
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
              Text(value,
                style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 4, offset: const Offset(-2, -2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.9), primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                    style: const TextStyle(color: textLight, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, color: textLight, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
              style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
