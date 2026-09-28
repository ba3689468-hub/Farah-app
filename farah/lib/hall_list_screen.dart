import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});
  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  static const Color gold      = Color(0xFF532527);
  static const Color lightGold = Color(0xFFE3DAD3);
  static const Color rose      = Color(0xFFE3DAD3);
  static const Color deepRose  = Color(0xFF532527);
  static const Color cream     = Color(0xFFF3E7E4);
  static const Color chocolate = Color(0xFF532527);

  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  String _selectedCity = 'الكل';
  late Future<QuerySnapshot> _hallsFuture;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'قاعات',  'emoji': '🎉', 'color': Color(0xFF532527)},
    {'name': 'تجميل',  'emoji': '💄', 'color': Color(0xFF874744)},
    {'name': 'ضيافة',  'emoji': '🍽️', 'color': Color(0xFFB98A7F)},
    {'name': 'فساتين', 'emoji': '👗', 'color': Color(0xFF874744)},
    {'name': 'ديكورات','emoji': '✨', 'color': Color(0xFF532527)},
  ];

  final List<String> _cities = const [
    'الكل', 'طرابلس', 'بنغازي', 'مصراتة', 'زليتن', 'سبها', 'البيضاء', 'الزاوية',
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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SimpleProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
            body: IndexedStack(
        index: _currentIndex,
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildBannerCarousel(),
                const SizedBox(height: 12),
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
          const Center(child: Text('البحث قريباً', style: TextStyle(fontSize: 18))),
          const Center(child: Text('المفضلة قريباً', style: TextStyle(fontSize: 18))),
          const SimpleProfileScreen(),
        ],
      ),
    );
  }


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

  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: (cat['color'] as Color).withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    cat['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(cat['name'] as String,
                style: const TextStyle(
                  color: chocolate, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          );
        },
      ),
    );
  }

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
                gradient: selected ? const LinearGradient(colors: [gold, deepRose]) : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : rose.withOpacity(0.5)),
                boxShadow: selected ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
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

  Widget _buildHallsList() {
    return FutureBuilder<QuerySnapshot>(
      future: _hallsFuture,
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
                ],
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString();
          final matchesSearch = _searchText.isEmpty || name.contains(_searchText.toLowerCase());
          final matchesCity = _selectedCity == 'الكل' || city == _selectedCity;
          return matchesSearch && matchesCity;
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState();

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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
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

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'الرئيسية'},
      {'icon': Icons.search_outlined, 'active': Icons.search, 'label': 'البحث'},
      {'icon': Icons.favorite_border, 'active': Icons.favorite, 'label': 'المفضلة'},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'حسابي'},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: gold.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final active = i == _currentIndex;
          return GestureDetector(
            onTap: () => setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: active ? 18 : 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                  ? const LinearGradient(colors: [gold, deepRose], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                    color: active ? Colors.white : Colors.black45,
                    size: 22,
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(items[i]['label'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

// ══════════════════════════════════════════
//  شاشة الحساب الشخصي (مدمجة لتجنب مشاكل import)
// ══════════════════════════════════════════
class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});
  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _userFuture = uid == null
        ? Future.error('no user')
        : FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  static const Color gold      = Color(0xFF532527);
  static const Color lightGold = Color(0xFFE3DAD3);
  static const Color deepRose  = Color(0xFF532527);
  static const Color cream     = Color(0xFFF3E7E4);
  static const Color chocolate = Color(0xFF532527);

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFF3E7E4),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.redAccent, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('تسجيل الخروج',
                style: TextStyle(
                  color: Color(0xFF532527),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
              const SizedBox(height: 8),
              const Text('هل أنت متأكد من تسجيل الخروج؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFF532527), width: 1.2),
                        ),
                      ),
                      child: const Text('إلغاء',
                        style: TextStyle(color: Color(0xFF532527), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('خروج',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
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
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
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
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 190,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [deepRose, gold, lightGold],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(70),
                          bottomRight: Radius.circular(70),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, right: 20, left: 20),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Row(
                              children: [
                                const Spacer(),
                                const Text('حسابي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                                    )),
                                const Spacer(),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -55,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: gold, width: 3),
                          boxShadow: [
                            BoxShadow(color: gold.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [gold, deepRose],
                            ).createShader(bounds),
                            child: Icon(isProvider ? Icons.storefront : Icons.person, size: 58, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 68),
                Text(name,
                    style: const TextStyle(color: chocolate, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gold, deepRose]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: gold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(isProvider ? 'مزوّد خدمة' : 'زبون',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: deepRose.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))],
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
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => _logout(context),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('تسجيل الخروج',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('فرح — الإصدار 1.0.0',
                    style: TextStyle(color: Colors.black38, fontSize: 12)),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [gold, deepRose],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(color: chocolate, fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}