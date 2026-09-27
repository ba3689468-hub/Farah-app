import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});
  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  static const Color gold      = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF4E5B1);
  static const Color rose      = Color(0xFFE8B4B8);
  static const Color deepRose  = Color(0xFFB76E79);
  static const Color cream     = Color(0xFFFFF8F0);
  static const Color chocolate = Color(0xFF3E2723);

  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  String _searchText = '';

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'قاعات', 'icon': Icons.celebration, 'key': 'venue'},
    {'name': 'تجميل', 'icon': Icons.face_retouching_natural, 'key': 'beauty'},
    {'name': 'ضيافة', 'icon': Icons.restaurant, 'key': 'catering'},
    {'name': 'فساتين', 'icon': Icons.checkroom, 'key': 'dresses'},
    {'name': 'ديكورات', 'icon': Icons.auto_awesome, 'key': 'decor'},
  ];

  final List<String> _cities = const [
    'الكل', 'طرابلس', 'بنغازي', 'مصراتة', 'زليتن', 'سبها', 'البيضاء', 'الزاوية',
  ];
  String _selectedCity = 'الكل';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildCategoriesRow(),
            const SizedBox(height: 14),
            _buildCitiesRow(),
            const SizedBox(height: 10),
            Expanded(child: _buildHallsList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── الشريط العلوي مع الترحيب ──
  Widget _buildTopBar() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'مرحباً';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // الأيقونة الشخصية
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [gold, deepRose],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مرحباً بك في', style: TextStyle(color: chocolate, fontSize: 12)),
                Text(name, style: const TextStyle(color: chocolate, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // زر تسجيل الخروج
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: deepRose),
          ),
        ],
      ),
    );
  }

  // ── حقل البحث ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: deepRose.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          const SizedBox(width: 18),
          const Icon(Icons.search, color: deepRose, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              textAlign: TextAlign.right,
              onChanged: (v) => setState(() => _searchText = v.trim()),
              decoration: const InputDecoration(
                hintText: 'ابحث عن صالة، خدمة، مدينة...',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ]),
      ),
    );
  }

  // ── الأقسام الأفقية ──
  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [gold, deepRose],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: gold.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 6),
              Text(cat['name'] as String,
                style: const TextStyle(color: chocolate, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          );
        },
      ),
    );
  }

  // ── شريط المدن ──
  Widget _buildCitiesRow() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final city = _cities[i];
          final selected = city == _selectedCity;
          return GestureDetector(
            onTap: () => setState(() => _selectedCity = city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                  ? const LinearGradient(colors: [gold, deepRose])
                  : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : rose.withOpacity(0.5)),
                boxShadow: selected
                  ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
              ),
              child: Center(
                child: Text(city,
                  style: TextStyle(
                    color: selected ? Colors.white : chocolate,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  )),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── قائمة الصالات من Firestore ──
  Widget _buildHallsList() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('halls').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: gold));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text('تعذر تحميل الصالات',
                    style: TextStyle(color: chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${snapshot.error}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // فلترة حسب البحث والمدينة
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString();
          final matchesSearch = _searchText.isEmpty || name.contains(_searchText.toLowerCase());
          final matchesCity = _selectedCity == 'الكل' || city == _selectedCity;
          return matchesSearch && matchesCity;
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            return _buildHallCard(data);
          },
        );
      },
    );
  }

  // ── بطاقة صالة ──
  Widget _buildHallCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'صالة بدون اسم';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: deepRose.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصورة
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [lightGold, rose],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: image != null
                ? Image.network(image, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.white70)))
                : const Center(child: Icon(Icons.celebration, size: 60, color: Colors.white70)),
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
                      child: Text(name,
                        style: const TextStyle(color: chocolate, fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.star, color: gold, size: 16),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                          style: const TextStyle(color: chocolate, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.location_on_outlined, color: deepRose, size: 16),
                  const SizedBox(width: 4),
                  Text(city, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '$price ',
                            style: const TextStyle(color: deepRose, fontSize: 18, fontWeight: FontWeight.bold)),
                          const TextSpan(text: 'د.ل / ليلة',
                            style: TextStyle(color: chocolate, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [gold, deepRose]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('احجز الآن',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── حالة عدم وجود بيانات ──
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 90, color: gold.withOpacity(0.6)),
            const SizedBox(height: 16),
            const Text('لا توجد صالات بعد',
              style: TextStyle(color: chocolate, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('سيتم عرض الصالات هنا عند إضافتها',
              style: TextStyle(color: Colors.black54, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── الشريط السفلي ──
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: deepRose.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 3) {
              Navigator.push(
                    context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                              );
                                  return;
                                    }
                                      setState(() => _currentIndex = i);
                                      },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: deepRose,
        unselectedItemColor: Colors.black38,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'البحث'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'المفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}