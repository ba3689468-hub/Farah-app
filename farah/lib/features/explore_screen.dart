import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:farah/core/constants/app_colors.dart';
import '../hall_details_screen.dart';
import '../core/widgets/shimmer_loading.dart';
import 'package:farah/features/product_details_screen.dart';

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

  late Future<List<Map<String, dynamic>>> _exploreDataFuture;
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedCategory = 'الكل';
  String _query = '';
  final List<String> _categories = ['الكل', 'قاعات أفراح', 'متاجر'];

  @override
  void initState() {
    super.initState();
    _exploreDataFuture = _getMixedData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _getMixedData();
    setState(() => _exploreDataFuture = future);
    await future;
  }

  Future<List<Map<String, dynamic>>> _getMixedData() async {
    final List<Map<String, dynamic>> mixedList = [];
    try {
      final hallsSnapshot =
          await FirebaseFirestore.instance.collection('halls').get();
      for (var doc in hallsSnapshot.docs) {
        final data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'hall';
        mixedList.add(data);
      }

      final storesSnapshot =
          await FirebaseFirestore.instance.collection('stores').get();
      for (var doc in storesSnapshot.docs) {
        final data = doc.data();
        data['_id'] = doc.id;
        data['_type'] = 'store';
        mixedList.add(data);
      }

      mixedList.shuffle();
      return mixedList;
    } catch (e) {
      throw Exception('حدث خطأ في جلب البيانات: $e');
    }
  }

  int _countFor(List<Map<String, dynamic>> all, String cat) {
    if (cat == 'قاعات أفراح') {
      return all.where((e) => e['_type'] == 'hall').length;
    }
    if (cat == 'متاجر') {
      return all.where((e) => e['_type'] == 'store').length;
    }
    return all.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _exploreDataFuture,
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            return Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategoryChips(all),
                Expanded(child: _buildBody(snapshot)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 24),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'استكشف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              Text(
                'اكتشف أجمل القاعات والمتاجر',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.trim()),
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Tajawal', color: textDark),
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو المدينة...',
            hintStyle: const TextStyle(
                fontFamily: 'Tajawal', color: textLight, fontSize: 13),
            prefixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: textLight, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            suffixIcon: const Icon(Icons.search, color: primary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<Map<String, dynamic>> all) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat;
          final count = _countFor(all, cat);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                    const SizedBox(width: 8),
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

  Widget _buildBody(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const ShimmerLoading();
    }

    if (snapshot.hasError) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: 'تعذر تحميل البيانات',
        subtitle: 'تحقق من الاتصال ثم حاول مجدداً',
        actionLabel: 'إعادة المحاولة',
        onAction: _refresh,
      );
    }

    var data = snapshot.data ?? [];
    if (data.isEmpty) {
      return _buildMessage(
        icon: Icons.storefront_outlined,
        title: 'لا توجد بيانات لعرضها',
        subtitle: 'ستظهر القاعات والمتاجر هنا',
      );
    }

    if (_selectedCategory == 'قاعات أفراح') {
      data = data.where((e) => e['_type'] == 'hall').toList();
    } else if (_selectedCategory == 'متاجر') {
      data = data.where((e) => e['_type'] == 'store').toList();
    }

    if (_query.isNotEmpty) {
      data = data.where((e) {
        final name = (e['name'] ?? '').toString();
        final city = (e['city'] ?? e['location'] ?? '').toString();
        return name.contains(_query) || city.contains(_query);
      }).toList();
    }

    if (data.isEmpty) {
      return _buildMessage(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج',
        subtitle: 'جرّب كلمة بحث أو قسماً مختلفاً',
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
        itemCount: data.length,
        itemBuilder: (context, i) => _buildModernCard(data[i], i),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
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
              child: Icon(icon, size: 48, color: primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
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
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: Text(actionLabel,
                    style: const TextStyle(fontFamily: 'Tajawal')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(Map<String, dynamic> item, int index) {
    final isHall = item['_type'] == 'hall';
    final name = (item['name'] ?? (isHall ? 'قاعة' : 'متجر')).toString();
    final city = (item['city'] ?? item['location'] ?? 'غير محدد').toString();
    final price = item['price'] ?? 0;
    final rating = double.tryParse(item['rating']?.toString() ?? '0') ?? 0.0;
    final image = item['image'] ?? item['coverImage'];
    final hasImage = image != null && image.toString().isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (isHall) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HallDetailsScreen(hallData: item)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                productData: item,
                storeData: item,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: image.toString(),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: primary.withValues(alpha: 0.08)),
                        errorWidget: (context, url, error) =>
                            _imageFallback(isHall),
                      )
                    : _imageFallback(isHall),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 0.7, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        primaryDark.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isHall ? Icons.celebration : Icons.storefront,
                          color: primary, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        isHall ? 'قاعة' : 'متجر',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (rating > 0)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [primary, primaryDark]),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$price د.ل',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  Widget _imageFallback(bool isHall) {
    return Container(
      color: primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(isHall ? Icons.celebration : Icons.storefront,
            color: primary, size: 56),
      ),
    );
  }
}
