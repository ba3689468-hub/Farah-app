import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:farah/core/constants/app_colors.dart';
import 'store_details_screen.dart';
import 'package:farah/cart_provider.dart';
import 'package:farah/cart_screen.dart';

class StoresListScreen extends ConsumerStatefulWidget {
  final String initialCategory;

  const StoresListScreen({super.key, this.initialCategory = 'الكل'});

  @override
  ConsumerState<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends ConsumerState<StoresListScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  late String _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<String> _categories = [
    'الكل',
    'فساتين وأزياء',
    'تجميل وعطور',
    'ضيافة وحلويات',
    'ديكور وتجهيزات',
    'تصوير وفيديو',
    'كوش وأعراس',
    'أحذية',
    'ملابس نسائية',
    'مجوهرات',
    'هدايا',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'الكل': Icons.apps_rounded,
    'فساتين وأزياء': Icons.checkroom_rounded,
    'تجميل وعطور': Icons.spa_rounded,
    'ضيافة وحلويات': Icons.cake_rounded,
    'ديكور وتجهيزات': Icons.chair_rounded,
    'تصوير وفيديو': Icons.camera_alt_rounded,
    'كوش وأعراس': Icons.celebration_rounded,
    'أحذية': Icons.snowshoeing_rounded,
    'ملابس نسائية': Icons.dry_cleaning_rounded,
    'مجوهرات': Icons.diamond_rounded,
    'هدايا': Icons.card_giftcard_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'الكل';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesCategory(Map<String, dynamic> store, String cat) {
    if (cat == 'الكل') return true;
    final type = (store['type'] ?? '').toString();
    if (type.isEmpty) return false;
    return type.contains(cat) || cat.contains(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final all = docs
              .map((d) => <String, dynamic>{
                    ...(d.data() as Map<String, dynamic>),
                    '_id': d.id,
                  })
              .toList();

          return Column(
            children: [
              _buildHeader(),
              _buildCategoryChips(all),
              Expanded(child: _buildBody(snapshot, all)),
            ],
          );
        },
      ),
    );
  }

  // ───────────── الترويسة ─────────────
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _headerButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              const Text(
                'المتاجر',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _buildCartButton(),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Tajawal', color: textDark),
              decoration: InputDecoration(
                hintText: 'ابحث عن متجر أو تصنيف...',
                hintStyle: const TextStyle(
                    fontFamily: 'Tajawal', color: textLight, fontSize: 13),
                prefixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close,
                            color: textLight, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                suffixIcon: const Icon(Icons.search_rounded, color: primary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildCartButton() {
    return Consumer(
      builder: (context, ref, child) {
        final cartItems = ref.watch(cartProvider);
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 20),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '${cartItems.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ───────────── الفلاتر ─────────────
  Widget _buildCategoryChips(List<Map<String, dynamic>> all) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat;
          final count = all.where((s) => _matchesCategory(s, cat)).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [primary, primaryDark])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : primary.withValues(alpha: 0.15),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[cat] ?? Icons.store_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: isSelected ? Colors.white : textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (all.isNotEmpty) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: isSelected ? Colors.white : primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────── المحتوى ─────────────
  Widget _buildBody(
      AsyncSnapshot<QuerySnapshot> snapshot, List<Map<String, dynamic>> all) {
    if (snapshot.connectionState == ConnectionState.waiting && all.isEmpty) {
      return _buildSkeleton();
    }

    if (snapshot.hasError) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: 'تعذر تحميل المتاجر',
        subtitle: 'تحقق من الاتصال ثم حاول مجدداً',
      );
    }

    var stores =
        all.where((s) => _matchesCategory(s, _selectedCategory)).toList();

    if (_query.isNotEmpty) {
      stores = stores.where((s) {
        final name = (s['name'] ?? '').toString();
        final type = (s['type'] ?? '').toString();
        final location = (s['location'] ?? '').toString();
        return name.contains(_query) ||
            type.contains(_query) ||
            location.contains(_query);
      }).toList();
    }

    if (stores.isEmpty) {
      return _buildMessage(
        icon: _query.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.storefront_outlined,
        title:
            _query.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد متاجر في هذا القسم',
        subtitle: _query.isNotEmpty
            ? 'جرّب كلمة بحث مختلفة'
            : 'جرّب قسماً آخر أو عد لاحقاً',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: stores.length,
      itemBuilder: (context, i) {
        final store = stores[i];
        return _buildStoreCard(store, store['_id'].toString(), i);
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: 4,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 130,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(24)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _skeletonBar(120, 16),
                      const SizedBox(height: 12),
                      _skeletonBar(80, 12),
                      const SizedBox(height: 12),
                      _skeletonBar(100, 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.5, end: 1, duration: 800.ms);
      },
    );
  }

  Widget _skeletonBar(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 48, color: primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Tajawal', color: textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── بطاقة المتجر ─────────────
  Widget _buildStoreCard(
      Map<String, dynamic> store, String storeId, int index) {
    final name = (store['name'] ?? 'متجر').toString();
    final type = (store['type'] ?? '').toString();
    final location = (store['location'] ?? store['city'] ?? '').toString();
    final rating = double.tryParse(store['rating']?.toString() ?? '0') ?? 0.0;
    final image = store['image'] ?? store['logo'] ?? store['coverImage'];
    final hasImage = image != null && image.toString().isNotEmpty;

    final storeData = Map<String, dynamic>.from(store)..remove('_id');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StoreDetailsScreen(storeId: storeId, storeData: storeData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primary.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? CachedNetworkImage(
                            imageUrl: image.toString(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                                color: primary.withValues(alpha: 0.08)),
                            errorWidget: (context, url, error) =>
                                _coverFallback(type),
                          )
                        : _coverFallback(type),
                    if (rating > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (type.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: textLight, size: 15),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [primary, primaryDark]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'زيارة المتجر',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 11),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 450.ms,
          delay: (60 * (index > 6 ? 6 : index)).ms,
        )
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  Widget _coverFallback(String type) {
    IconData icon = Icons.storefront_rounded;
    _categoryIcons.forEach((key, value) {
      if (key != 'الكل' &&
          type.isNotEmpty &&
          (type.contains(key) || key.contains(type))) {
        icon = value;
      }
    });
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primaryDark.withValues(alpha: 0.25),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primary, size: 32),
        ),
      ),
    );
  }
}
