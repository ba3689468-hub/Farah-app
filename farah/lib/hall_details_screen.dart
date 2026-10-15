import 'package:farah/core/constants/app_colors.dart';
import 'package:farah/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'features/add_review_screen.dart';

class HallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  final String? hallId;
  final DateTime? prefilledDate;
  final String? prefilledEventType;
  final String? prefilledTimeSlot;

  const HallDetailsScreen({
    super.key,
    required this.hallData,
    this.hallId,
    this.prefilledDate,
    this.prefilledEventType,
    this.prefilledTimeSlot,
  });

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  static const double APP_COMMISSION = 60.0;

  DateTime? _selectedDate;
  String? _selectedEventType;
  String? _selectedTimeSlot;
  int _guestsCount = 50;

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _bookedDates = {};
  bool _loadingBookings = true;

  final _pageCtrl = PageController();
  int _currentImage = 0;

  bool _loading = false;
  late Map<String, dynamic> _hall;

  static const List<String> _timeSlots = [
    'الفترة الصباحية',
    'الفترة العصرية',
    'الفترة المسائية',
  ];

  final List<Map<String, dynamic>> _eventTypes = const [
    {'name': 'حفل زفاف', 'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {'name': 'محضر', 'icon': Icons.home_outlined, 'color': Color(0xFF9C27B0)},
    {'name': 'عقد قران', 'icon': Icons.auto_stories_outlined, 'color': Color(0xFF3F51B5)},
    {'name': 'أسبوع', 'icon': Icons.child_care_outlined, 'color': Color(0xFFFF9800)},
    {'name': 'حفل تخرج', 'icon': Icons.school_outlined, 'color': Color(0xFF4CAF50)},
    {'name': 'فضانية', 'icon': Icons.diamond_outlined, 'color': Color(0xFF009688)},
  ];

  @override
  void initState() {
    super.initState();
    _hall = Map<String, dynamic>.from(widget.hallData);
    _selectedDate = widget.prefilledDate;
    _selectedEventType = widget.prefilledEventType;
    _selectedTimeSlot = widget.prefilledTimeSlot;
    if (_selectedDate != null) {
      _calendarMonth = DateTime(_selectedDate!.year, _selectedDate!.month);
    }
    _loadBookedDates();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _hallId => widget.hallId ?? _hall['_id'] ?? _hall['id'] ?? '';

  int get _basePrice {
    final p = _hall['price'] ?? 0;
    return p is int ? p : int.tryParse(p.toString()) ?? 0;
  }

  Future<void> _loadBookedDates() async {
    if (_hallId.isEmpty) {
      if (mounted) setState(() => _loadingBookings = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('hallId', isEqualTo: _hallId)
          .get();

      final Set<String> booked = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'cancelled' || status == 'expired') continue;

        final eventDate = data['eventDate'] as Timestamp?;
        if (eventDate == null) continue;
        final d = eventDate.toDate();
        booked.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }

      if (mounted) {
        setState(() {
          _bookedDates = booked;
          _loadingBookings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBookings = false);
    }
  }

  bool _isDateBooked(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _bookedDates.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final name = _hall['name'] ?? 'صالة بدون اسم';
    final city = _hall['city'] ?? 'غير محدد';
    final rating = (_hall['rating'] ?? 0).toDouble();
    final description = _hall['description'] ?? 'لا يوجد وصف متاح.';
    final capacity = _hall['capacity'] ?? 0;
    final images = _getImages(_hall);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: textDark, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: textDark, size: 20),
                ),
                onPressed: _shareHall,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(images),
            ),
          ),
          if (images.length > 1)
            SliverToBoxAdapter(child: _buildThumbnails(images)),

          SliverToBoxAdapter(
            child: _buildInfoSection(name, city, rating, capacity, description),
          ),

          SliverToBoxAdapter(child: _buildBookingCard()),

          SliverToBoxAdapter(child: _buildPaymentSummaryCard()),

          SliverToBoxAdapter(child: _buildReviewsSection()),
          SliverToBoxAdapter(child: _buildSimilarHallsSection(city)),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<String> _getImages(Map<String, dynamic> hall) {
    final gallery = hall['gallery'];
    if (gallery is List && gallery.isNotEmpty) return List<String>.from(gallery);
    final single = hall['image'] ?? hall['coverImage'];
    if (single != null && single.toString().isNotEmpty) return [single.toString()];
    return [];
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: primary.withValues(alpha: 0.3),
        child: Center(child: Icon(Icons.celebration, size: 80, color: Colors.white.withValues(alpha: 0.6))),
      );
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageCtrl,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentImage = i),
          itemBuilder: (context, i) => Image.network(
            images[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: primary.withValues(alpha: 0.3),
              child: Center(child: Icon(Icons.celebration, size: 80, color: Colors.white.withValues(alpha: 0.6))),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, primaryDark.withValues(alpha: 0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 16, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _currentImage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        Positioned(
          top: 90, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
            ),
            child: Text('$_basePrice د.ل / ليلة',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
        Positioned(
          bottom: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text((_hall['rating'] ?? 0).toStringAsFixed(1),
                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('${_currentImage + 1}/${images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnails(List<String> images) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = i == _currentImage;
          return GestureDetector(
            onTap: () => _pageCtrl.animateToPage(i,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? primary : Colors.transparent, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: primary.withValues(alpha: 0.2),
                    child: const Icon(Icons.broken_image, color: primary, size: 20),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String name, String city, double rating, int capacity, String description) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name,
                  style: const TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('مميزة', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: primary, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(city, style: const TextStyle(color: textLight, fontSize: 14))),
              GestureDetector(
                onTap: () => _openDirections(city, name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions, color: primary, size: 16),
                      SizedBox(width: 4),
                      Text('الاتجاهات', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _compactInfoCard(Icons.payments_outlined, '$_basePrice', 'د.ل/ليلة', primaryDark),
              const SizedBox(width: 8),
              _compactInfoCard(Icons.people_outline, '$capacity', 'السعة', primary),
              const SizedBox(width: 8),
              _compactInfoCard(Icons.star, rating.toStringAsFixed(1), 'التقييم', Colors.amber),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.description_outlined, color: primary, size: 20),
              SizedBox(width: 6),
              Text('الوصف', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: textDark, fontSize: 14, height: 1.7)),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.room_service_outlined, color: primary, size: 20),
              SizedBox(width: 6),
              Text('المرافق والخدمات', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _buildAmenitiesFromData()),
        ],
      ),
    );
  }

  List<Widget> _buildAmenitiesFromData() {
    final amenities = _hall['amenities'];
    if (amenities == null || amenities is! List || amenities.isEmpty) {
      return [const Text('لم يتم إضافة مرافق', style: TextStyle(color: textLight, fontSize: 13))];
    }
    return amenities.map<Widget>((a) => _amenityChip(a.toString())).toList();
  }

  Widget _compactInfoCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: textLight, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _amenityChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: primary, size: 14),
          const SizedBox(width: 5),
          Text(name, style: const TextStyle(color: textDark, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available, color: primary, size: 22),
              SizedBox(width: 8),
              Text('تفاصيل الحجز',
                  style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          const Text('نوع المناسبة', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _eventTypes.map((type) {
              final selected = _selectedEventType == type['name'];
              final color = type['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedEventType = type['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.15) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type['icon'] as IconData,
                          color: selected ? color : textLight, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        type['name'] as String,
                        style: TextStyle(
                          color: selected ? color : textDark,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildPickerField(
                icon: Icons.calendar_today_outlined,
                label: 'التاريخ',
                value: _selectedDate != null
                    ? DateFormat('d MMM yyyy', 'ar').format(_selectedDate!)
                    : null,
                onTap: _pickDate,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildPickerField(
                icon: Icons.access_time,
                label: 'الفترة',
                value: _selectedTimeSlot,
                onTap: _pickTimeSlot,
              )),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text('عدد الضيوف',
                    style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                _counterBtn(
                  icon: Icons.remove,
                  onTap: _guestsCount > 10
                      ? () => setState(() => _guestsCount -= 10)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('$_guestsCount',
                      style: const TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _counterBtn(
                  icon: Icons.add,
                  onTap: _guestsCount < 1000
                      ? () => setState(() => _guestsCount += 10)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('تقويم التوفر',
              style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildVisualCalendar(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: primary, size: 22),
              SizedBox(width: 8),
              Text('ملخص الدفع',
                  style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),

          _paymentRow(
            icon: Icons.home_outlined,
            label: 'سعر القاعة (يُدفع في القاعة)',
            value: '$_basePrice د.ل',
            color: textDark,
          ),
          const Divider(height: 20),

          _paymentRow(
            icon: Icons.app_registration,
            label: 'رسم حجز التطبيق (يُدفع الآن)',
            value: '${APP_COMMISSION.toInt()} د.ل',
            color: primary,
            bold: true,
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('المطلوب دفعه الآن',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                Text('${APP_COMMISSION.toInt()} د.ل',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.policy_outlined, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('سياسة الإلغاء',
                        style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                _policyItem(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  text: 'استرداد كامل (60 د.ل) خلال 48 ساعة من الحجز',
                ),
                const SizedBox(height: 6),
                _policyItem(
                  icon: Icons.cancel_outlined,
                  color: Colors.redAccent,
                  text: 'لا يوجد استرداد بعد مرور 48 ساعة',
                ),
                const SizedBox(height: 6),
                _policyItem(
                  icon: Icons.info_outline,
                  color: Colors.blueGrey,
                  text: 'إذا لم تتوجه للقاعة خلال 48 ساعة، يُلغى الحجز تلقائياً',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: bold ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _policyItem({required IconData icon, required Color color, required String text}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: textDark, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerField({
    required IconData icon,
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasValue ? primary.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? primary.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? value : label,
                style: TextStyle(
                  color: hasValue ? textDark : textLight,
                  fontSize: 12,
                  fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: textLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _counterBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: enabled ? primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: enabled ? primary : Colors.black26, size: 18),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📅 التقويم — كل الأيام بيضاء، اليوم المختار أخضر،
  // "محجوز" يظهر فقط عند اختيار يوم محجوز فعلياً
  // ═══════════════════════════════════════════════════════════
  Widget _buildVisualCalendar() {
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final offset = (firstWeekday + 1) % 7;

    final monthName = DateFormat('MMMM yyyy', 'ar').format(_calendarMonth);

    List<Widget> cells = [];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
      final isPast = date.isBefore(todayMidnight);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      Color bg;
      Color fg;
      if (isPast) {
        bg = Colors.grey.withValues(alpha: 0.08);
        fg = Colors.grey;
      } else if (isSelected) {
        bg = Colors.green;
        fg = Colors.white;
      } else {
        bg = Colors.white;
        fg = textDark;
      }

      cells.add(
        GestureDetector(
          onTap: isPast
              ? null
              : () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Colors.green.shade700, width: 2)
                  : Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() =>
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right, color: primary, size: 18),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(monthName,
                      style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() =>
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_left, color: primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),

          // ✅ عرض "محجوز" فقط عند اختيار يوم محجوز فعلياً
          if (_selectedDate != null && _isDateBooked(_selectedDate!)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'محجوز — ${DateFormat('EEEE d MMMM yyyy', 'ar').format(_selectedDate!)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final rating = (_hall['rating'] ?? 0).toDouble();
    final reviewsCount = _hall['reviewsCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reviews_outlined, color: primary, size: 20),
              const SizedBox(width: 6),
              const Text('التقييمات',
                  style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _openAddReview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: primary, size: 16),
                      SizedBox(width: 4),
                      Text('أضف تقييم',
                          style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text(rating.toStringAsFixed(1),
                      style: const TextStyle(color: primary, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber, size: 20);
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text('$reviewsCount مراجعة',
                          style: const TextStyle(color: textLight, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('hallId', isEqualTo: _hallId)
                .limit(3)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              final reviews = snap.data!.docs;
              if (reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: textLight, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text('لا توجد مراجعات بعد. كن أول من يشارك تجربته!',
                          style: TextStyle(color: textLight, fontSize: 12))),
                    ],
                  ),
                );
              }

              final sortedReviews = List<QueryDocumentSnapshot>.from(reviews);
              sortedReviews.sort((a, b) {
                final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                if (aT == null && bT == null) return 0;
                if (aT == null) return 1;
                if (bT == null) return -1;
                return bT.compareTo(aT);
              });

              return Column(
                children: sortedReviews.map((doc) => _buildReviewItem(doc.data() as Map<String, dynamic>)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAddReview() async {
    if (_hallId.isEmpty) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddReviewScreen(hallId: _hallId, hallName: _hall['name'] ?? '')),
    );
    if (result == true && mounted) {
      try {
        final doc = await FirebaseFirestore.instance.collection('halls').doc(_hallId).get();
        if (doc.exists && mounted) {
          setState(() {
            _hall = Map<String, dynamic>.from(doc.data()!);
            _hall['_id'] = doc.id;
          });
        }
      } catch (_) {}
    }
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = review['userName'] ?? 'مستخدم';
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primary, primaryDark]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0] : 'م',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(userName, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold))),
              Row(children: List.generate(5, (i) {
                return Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 12);
              })),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(color: textDark, fontSize: 12, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarHallsSection(String city) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(width: 4, height: 20,
                    decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text('قاعات مشابهة',
                    style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('halls')
                  .where('city', isEqualTo: city)
                  .limit(6)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final halls = snap.data!.docs.where((doc) => doc.id != _hallId).toList();
                if (halls.isEmpty) return const SizedBox();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: halls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final data = halls[i].data() as Map<String, dynamic>;
                    data['_id'] = halls[i].id;
                    return _buildSimilarCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarCard(Map<String, dynamic> hall) {
    final name = hall['name'] ?? 'قاعة';
    final city = hall['city'] ?? '';
    final price = hall['price'] ?? 0;
    final rating = (hall['rating'] ?? 0).toDouble();
    final image = hall['image'] ?? hall['coverImage'];

    return GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => HallDetailsScreen(hallData: hall))),
      child: Container(
        width: 160,
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
              child: SizedBox(
                height: 100, width: 160,
                child: (image != null && image.toString().isNotEmpty)
                    ? Image.network(image.toString(), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.celebration, color: Colors.white, size: 40)))
                    : Container(color: primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.celebration, color: Colors.white, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(city, style: const TextStyle(color: textLight, fontSize: 10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$price د.ل', style: const TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      Row(children: [
                        const Icon(Icons.star, color: Colors.amber, size: 10),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('المطلوب دفعه الآن',
                      style: TextStyle(color: textLight, fontSize: 11)),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '${APP_COMMISSION.toInt()} ',
                          style: const TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const TextSpan(text: 'د.ل', style: TextStyle(color: textDark, fontSize: 13)),
                    ]),
                  ),
                  Text('+ $_basePrice د.ل في القاعة',
                      style: const TextStyle(color: textLight, fontSize: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _callProvider,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3), width: 1.5),
                ),
                child: const Icon(Icons.phone_outlined, color: primary, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loading ? null : _confirmBooking,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 15, offset: const Offset(0, 6))],
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('احجز الآن',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calendarMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _pickTimeSlot() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('اختر الفترة الزمنية',
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              final icons = {
                'الفترة الصباحية': Icons.wb_sunny_outlined,
                'الفترة العصرية': Icons.wb_twilight_outlined,
                'الفترة المسائية': Icons.nightlight_round_outlined,
              };
              return ListTile(
                leading: Icon(icons[slot] ?? Icons.access_time, color: isSelected ? primary : textLight),
                title: Text(slot,
                    style: TextStyle(color: isSelected ? primary : textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check, color: primary) : null,
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

  Future<void> _confirmBooking() async {
    if (_selectedEventType == null) {
      _showError('الرجاء اختيار نوع المناسبة');
      return;
    }
    if (_selectedDate == null) {
      _showError('الرجاء اختيار تاريخ الحجز');
      return;
    }
    if (_selectedTimeSlot == null) {
      _showError('الرجاء اختيار الفترة الزمنية');
      return;
    }

    if (_isDateBooked(_selectedDate!)) {
      _showError('هذا التاريخ محجوز بالفعل. اختر تاريخاً آخر.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('الرجاء تسجيل الدخول');
      return;
    }

    final bool? shouldPay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.payment, color: primary, size: 28),
            SizedBox(width: 10),
            Text('دفع رسم الحجز', style: TextStyle(color: textDark, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لإتمام الحجز المبدئي، يجب دفع رسم حجز قدره:',
                style: TextStyle(color: textDark, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Center(
                child: Text('60 دينار ليبي',
                    style: TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'هذا المبلغ هو رسم حجز مبدئي للتطبيق فقط.\nسعر القاعة الكامل يُدفع نقداً لصاحب القاعة عند الحضور.',
              style: TextStyle(color: textLight, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Expanded(child: Text('يحق لك استرداد المبلغ كاملاً خلال 48 ساعة من الحجز',
                      style: TextStyle(color: Colors.orange, fontSize: 11))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('دفع 60 د.ل'),
          ),
        ],
      ),
    );

    if (shouldPay != true) return;

    setState(() => _loading = true);

    try {
      final total = _basePrice;
      final expiresAt = DateTime.now().add(const Duration(hours: 48));

      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'userId': uid,
        'hallId': _hallId,
        'hallName': _hall['name'] ?? '',
        'hallImage': _hall['image'] ?? _hall['coverImage'] ?? '',
        'eventType': _selectedEventType,
        'timeSlot': _selectedTimeSlot,
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'guestsCount': _guestsCount,
        'basePrice': _basePrice,
        'totalPrice': total,
        'commission': APP_COMMISSION,
        'providerNet': total,
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'refundEligibleUntil': Timestamp.fromDate(expiresAt),
      });

      await bookingRef.update({'paymentStatus': 'commission_paid'});

      try {
        final hallDoc = await FirebaseFirestore.instance.collection('halls').doc(_hallId).get();
        final providerId = hallDoc.data()?['providerId'] ?? '';
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final customerName = userDoc.data()?['fullName'] ?? 'زبون';

        if (providerId.toString().isNotEmpty) {
          await NotificationHelper.notifyProviderNewBooking(
            providerId: providerId.toString(),
            hallName: _hall['name'] ?? 'قاعة',
            customerName: customerName,
            bookingId: bookingRef.id,
          );
        }
      } catch (_) {}

      setState(() {
        _bookedDates = {
          ..._bookedDates,
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
        };
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('تم الحجز المبدئي!', style: TextStyle(color: textDark, fontSize: 18)),
            ],
          ),
          content: Text(
            'تم دفع رسم الحجز بنجاح (60 د.ل).\n\n'
            'لديك 48 ساعة للتوجه إلى "${_hall['name'] ?? 'القاعة'}" ودفع سعر القاعة كاملاً ($total د.ل).\n\n'
            'خلال هذه المدة يمكنك إلغاء الحجز واسترداد 60 د.ل كاملة من "حجوزاتي".',
            style: const TextStyle(color: textDark, fontSize: 14, height: 1.6),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('فشل الحجز: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _callProvider() async {
    final phone = _hall['providerPhone'] ?? _hall['phone'] ?? _hall['contactPhone'] ?? '';
    if (phone.toString().trim().isEmpty) {
      _showError('لا يوجد رقم هاتف متاح للمزود');
      return;
    }

    String cleanPhone = phone.toString().replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('00')) cleanPhone = cleanPhone.substring(2);
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+218${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('218')) {
        cleanPhone = '+$cleanPhone';
      } else {
        cleanPhone = '+218$cleanPhone';
      }
    }

    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError('تعذر فتح الاتصال: $cleanPhone');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> _openDirections(String city, String name) async {
    final lat = _hall['latitude'];
    final lng = _hall['longitude'];
    Uri uri;

    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final query = Uri.encodeComponent('$name $city ليبيا');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('تعذر فتح الخرائط');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> _shareHall() async {
    final name = _hall['name'] ?? 'قاعة';
    final city = _hall['city'] ?? '';
    final rating = (_hall['rating'] ?? 0).toStringAsFixed(1);

    final text = '🎉 اكتشف $name على تطبيق فرح!\n\n'
        '📍 المدينة: $city\n'
        '💰 السعر: $_basePrice د.ل\n'
        '⭐ التقييم: $rating\n\n'
        '📱 حمّل تطبيق فرح من هنا:\n'
        'https://github.com/ba3689468-hub/Farah-app/releases';

    try {
      await Share.share(text, subject: 'قاعة $name على تطبيق فرح');
    } catch (e) {
      _showError('تعذر المشاركة: $e');
    }
  }
}
