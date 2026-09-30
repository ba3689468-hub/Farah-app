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
  static const Color gold      = Color(0xFFD7BDB0);
  static const Color lightGold = Color(0xFFEDEEE9);
  static const Color rose      = Color(0xFFEDEEE9);
  static const Color deepRose  = Color(0xFFD7BDB0);
  static const Color cream     = Color(0xFFF5EBE1);
  static const Color chocolate = Color(0xFFD7BDB0);

  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  String _selectedCity = 'الكل';
  late Future<QuerySnapshot> _hallsFuture;
  bool _isGrid = false;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'قاعات',  'icon': Icons.meeting_room,     'color': Color(0xFFD7BDB0)},
    {'name': 'تجميل',  'icon': Icons.spa,              'color': Color(0xFFD7BDB0)},
    {'name': 'ضيافة',  'icon': Icons.restaurant_menu,  'color': Color(0xFFD7BDB0)},
    {'name': 'فساتين', 'icon': Icons.checkroom,        'color': Color(0xFFD7BDB0)},
    {'name': 'ديكورات','icon': Icons.palette,          'color': Color(0xFFD7BDB0)},
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
      MaterialPageRoute(builder: (_) => const FarahGlassLoginScreen()),
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
                _buildTopHeader(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildBannerCarousel(),
                const SizedBox(height: 12),
                _buildCategoriesRow(),
                const SizedBox(height: 14),
                _buildCitiesRow(),
                const SizedBox(height: 10),
                _buildViewToggle(),
                const SizedBox(height: 6),
                Expanded(child: _buildHallsList()),
              ],
            ),
          ),
          const Center(child: Text('البحث قريباً', style: TextStyle(fontSize: 18))),
          const Center(child: Text('المفضلة قريباً', style: TextStyle(fontSize: 18))),
          const SimpleProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  // ═══ بانر الإعلانات والعروض ═══
  Widget _buildBannerCarousel() {
    final banners = [
      {'title': 'خصم 20% على قاعات طرابلس', 'sub': 'لفترة محدودة', 'image': 'https://picsum.photos/seed/hall1/600/300'},
      {'title': 'احجز صالتك الآن', 'sub': 'استشارة مجانية', 'image': 'https://picsum.photos/seed/hall2/600/300'},
      {'title': 'عروض الضيافة', 'sub': 'أسعار تنافسية', 'image': 'https://picsum.photos/seed/hall3/600/300'},
    ];
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: banners.length,
        itemBuilder: (context, i) {
          final b = banners[i];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: gold.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(b['image'] as String, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: gold)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [gold.withOpacity(0.9), Colors.transparent],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(b['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 6)]),
                          textAlign: TextAlign.right),
                        const SizedBox(height: 4),
                        Text(b['sub'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [gold, deepRose], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('0 د.ل', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الإشعارات قريباً')));
            },
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.notifications_none, color: gold, size: 18),
            ),
          ),
          const Spacer(),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [gold, deepRose]),
              boxShadow: [BoxShadow(color: gold.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Center(child: Text('ف', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('مرحباً بك في', style: TextStyle(color: Colors.black45, fontSize: 10)),
              Text('فرح', style: TextStyle(color: chocolate, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Color(0xFFD7BDB0), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textAlign: TextAlign.right,
                      onChanged: (v) => setState(() => _searchText = v.trim()),
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن صالة، خدمة، مدينة...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD7BDB0), Color(0xFFC4B5A9)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFFD7BDB0).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }



  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cream,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFEDEEE9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('الفلترة والبحث المتقدم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: chocolate)),
              const SizedBox(height: 22),
              const Text('المدينة', style: TextStyle(fontWeight: FontWeight.bold, color: chocolate, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _cities.map((c) => GestureDetector(
                  onTap: () { setSheet(() {}); setState(() => _selectedCity = c); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCity == c ? gold : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(0.3)),
                    ),
                    child: Text(c, style: TextStyle(color: _selectedCity == c ? Colors.white : chocolate, fontSize: 13)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 22),
              const Text('السعر', style: TextStyle(fontWeight: FontWeight.bold, color: chocolate, fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const Row(children: [
                  Icon(Icons.attach_money, color: gold, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('من 0 د.ل  إلى  20000 د.ل', style: TextStyle(color: chocolate, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 22),
              const Text('التقييم', style: TextStyle(fontWeight: FontWeight.bold, color: chocolate, fontSize: 14)),
              const SizedBox(height: 10),
              Row(children: List.generate(5, (i) => const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.star, color: Colors.amber, size: 26),
              ))),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: const BorderSide(color: gold),
                  ),
                  child: Text('إعادة تعيين', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('تطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
                )),
              ]),
              const SizedBox(height: 10),
            ],
          ),
        ),
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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return Column(
            children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cat['color'] as Color, (cat['color'] as Color).withOpacity(0.75)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: (cat['color'] as Color).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 8),
              Text(cat['name'] as String,
                style: const TextStyle(color: chocolate, fontSize: 12, fontWeight: FontWeight.w600)),
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

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text('طريقة العرض',
            style: TextStyle(color: chocolate, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          _viewBtn(icon: Icons.view_list, isActive: !_isGrid, onTap: () => setState(() => _isGrid = false)),
          const SizedBox(width: 8),
          _viewBtn(icon: Icons.grid_view, isActive: _isGrid, onTap: () => setState(() => _isGrid = true)),
        ],
      ),
    );
  }

  Widget _viewBtn({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [gold, deepRose]) : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: gold.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.black38, size: 18),
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
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Icon(Icons.error_outline, size: 70, color: Colors.redAccent),
                SizedBox(height: 16),
                Text('تعذر تحميل الصالات', style: TextStyle(color: chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString();
          return (_searchText.isEmpty || name.contains(_searchText.toLowerCase())) &&
                 (_selectedCity == 'الكل' || city == _selectedCity);
        }).toList();

        if (filtered.isEmpty) return _buildEmptyState();

        if (_isGrid) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildHallGridCard(filtered[i].data() as Map<String, dynamic>),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildHallCard(filtered[i].data() as Map<String, dynamic>),
        );
      },
    );
  }

  Widget _buildHallGridCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'صالة';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: gold.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 110, width: double.infinity,
              child: image != null
                ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: gold.withOpacity(0.3), child: const Icon(Icons.celebration, color: Colors.white, size: 40)))
                : Container(color: gold.withOpacity(0.3), child: const Icon(Icons.celebration, color: Colors.white, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: chocolate, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, color: Colors.black38, size: 12),
                  const SizedBox(width: 2),
                  Expanded(child: Text(city, style: const TextStyle(color: Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('$price د.ل', style: const TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.star, color: gold, size: 12),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(color: chocolate, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHallCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'صالة بدون اسم';
    final city = hall['city'] ?? 'غير محدد';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall)),
        );
      },
      child: Container(
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
      {'icon': Icons.home_outlined, 'active': Icons.home},
      {'icon': Icons.search_outlined, 'active': Icons.search},
      {'icon': Icons.favorite_border, 'active': Icons.favorite},
      {'icon': Icons.person_outline, 'active': Icons.person},
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: gold.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
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
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [gold, deepRose], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: active ? null : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: active ? [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
              ),
              child: Icon(
                active ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                color: active ? Colors.white : Colors.black38,
                size: 24,
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

  static const Color gold      = Color(0xFFD7BDB0);
  static const Color lightGold = Color(0xFFEDEEE9);
  static const Color deepRose  = Color(0xFFD7BDB0);
  static const Color cream     = Color(0xFFF5EBE1);
  static const Color chocolate = Color(0xFFD7BDB0);

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cream,
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
                  color: Color(0xFFD7BDB0),
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
                          side: const BorderSide(color: Color(0xFFD7BDB0), width: 1.2),
                        ),
                      ),
                      child: const Text('إلغاء',
                        style: TextStyle(color: Color(0xFFD7BDB0), fontWeight: FontWeight.bold)),
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
      MaterialPageRoute(builder: (_) => const FarahGlassLoginScreen()),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                          ),
                          child: _profileTile(Icons.calendar_month, 'حجوزاتي'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: _profileTile(Icons.favorite_border, 'المفضلة'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: _profileTile(Icons.settings_outlined, 'الإعدادات'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: _profileTile(Icons.help_outline, 'المساعدة'),
                        ),
                      ),
                    ],
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

  Widget _profileTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD7BDB0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFD7BDB0), size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
            style: const TextStyle(color: Color(0xFF3E3530), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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