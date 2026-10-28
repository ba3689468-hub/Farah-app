import 'package:farah/core/constants/app_colors.dart';
import 'package:farah/core/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  final String? hallId;
  final DateTime? prefilledDate;
  final String? prefilledEventType;
  final String? prefilledTimeSlot;

  const BookingScreen({
    super.key,
    required this.hallData,
    this.hallId,
    this.prefilledDate,
    this.prefilledEventType,
    this.prefilledTimeSlot,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedEventType;
  int _guestsCount = 50;
  final List<String> _selectedServices = []; // نخزن أسماء الخدمات المختارة
  bool _loading = false;

  bool get _hasPrefilled =>
      widget.prefilledDate != null ||
      widget.prefilledEventType != null ||
      widget.prefilledTimeSlot != null;

  final List<Map<String, dynamic>> _eventTypes = const [
    {'name': 'حفل زفاف', 'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {'name': 'محضر', 'icon': Icons.home_outlined, 'color': Color(0xFF9C27B0)},
    {'name': 'عقد قران', 'icon': Icons.auto_stories_outlined, 'color': Color(0xFF3F51B5)},
    {'name': 'أسبوع', 'icon': Icons.child_care_outlined, 'color': Color(0xFFFF9800)},
    {'name': 'حفل تخرج', 'icon': Icons.school_outlined, 'color': Color(0xFF4CAF50)},
    {'name': 'فضانية', 'icon': Icons.diamond_outlined, 'color': Color(0xFF009688)},
  ];

  final List<Map<String, dynamic>> _timeSlots = const [
    {
      'name': 'الفترة الصباحية',
      'time': '10 ص - 2 م',
      'icon': Icons.wb_sunny_outlined,
      'color': Color(0xFFFFA726),
    },
    {
      'name': 'الفترة العصرية',
      'time': '2 م - 7 م',
      'icon': Icons.wb_twilight_outlined,
      'color': Color(0xFFFF7043),
    },
    {
      'name': 'الفترة المسائية',
      'time': '7 م - 12 ص',
      'icon': Icons.nightlight_round_outlined,
      'color': Color(0xFF5C6BC0),
    },
  ];

  // ✅ دالة لجلب الخدمات الإضافية من بيانات القاعة
  List<Map<String, dynamic>> get _availableServices {
    final services = widget.hallData['additionalServices'];
    if (services is List) {
      return services.map((s) => {
        'name': s['name'] ?? 'خدمة',
        'price': (s['price'] ?? 0).toDouble(),
      }).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.prefilledDate;
    _selectedEventType = widget.prefilledEventType;
    _selectedTimeSlot = widget.prefilledTimeSlot;
  }

  @override
  Widget build(BuildContext context) {
    final hall = widget.hallData;
    final name = hall['name'] ?? 'صالة';
    final basePrice = (hall['price'] ?? 0) is int
        ? hall['price'] as int
        : int.tryParse(hall['price'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('حجز القاعة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHallSummary(name, basePrice),
            const SizedBox(height: 8),
            if (_hasPrefilled)
              _buildPrefilledSummary()
            else ...[
              _buildEventTypeSection(),
              _buildCalendarSection(),
              _buildTimeSlotSection(),
            ],
            _buildGuestsSection(),
            
            // ✅ عرض الخدمات الإضافية (فقط إذا كانت موجودة)
            if (_availableServices.isNotEmpty) _buildServicesSection(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmBar(basePrice),
    );
  }

  Widget _buildPrefilledSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryDark]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'تفاصيل حجزك',
                  style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'تعديل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.prefilledEventType != null)
            _buildSummaryRow(Icons.celebration_outlined, 'نوع المناسبة', widget.prefilledEventType!),
          if (widget.prefilledDate != null)
            _buildSummaryRow(
              Icons.calendar_today_outlined,
              'التاريخ',
              DateFormat('EEEE، d MMMM yyyy', 'ar').format(widget.prefilledDate!),
            ),
          if (widget.prefilledTimeSlot != null)
            _buildSummaryRow(Icons.access_time, 'الفترة الزمنية', widget.prefilledTimeSlot!),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'يمكنك الآن إضافة عدد الضيوف والخدمات الإضافية، ثم تأكيد الحجز.',
                    style: TextStyle(fontFamily: 'Tajawal', color: Colors.orange, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallSummary(String name, int basePrice) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, primaryDark]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.celebration, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أنت تحجز في', style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 11)),
                const SizedBox(height: 3),
                Text(name,
                    style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$basePrice ',
                  style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 17, fontWeight: FontWeight.bold)),
              const TextSpan(text: 'د.ل', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeSection() {
    return _buildSection(
      title: 'نوع المناسبة',
      icon: Icons.celebration_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _eventTypes.map((type) {
          final selected = _selectedEventType == type['name'];
          final color = type['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedEventType = type['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? color : Colors.black.withValues(alpha: 0.08),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type['icon'] as IconData, color: selected ? color : textLight, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    type['name'] as String,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: selected ? color : textDark,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarSection() {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    return _buildSection(
      title: 'تاريخ المناسبة',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.15), width: 1),
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate ?? now,
              firstDate: firstDate,
              lastDate: lastDate,
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'التاريخ المختار: ${DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate!)}',
                      style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13, fontWeight: FontWeight.w600),
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

  Widget _buildTimeSlotSection() {
    return _buildSection(
      title: 'الفترة الزمنية',
      icon: Icons.access_time,
      child: Column(
        children: _timeSlots.map((slot) {
          final selected = _selectedTimeSlot == slot['name'];
          final color = slot['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = slot['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : Colors.black.withValues(alpha: 0.08),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: selected ? color : color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(slot['icon'] as IconData, color: selected ? Colors.white : color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot['name'] as String,
                              style: TextStyle(fontFamily: 'Tajawal', color: selected ? color : textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(slot['time'] as String, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? color : Colors.black.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        color: selected ? color : Colors.transparent,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuestsSection() {
    return _buildSection(
      title: 'عدد الضيوف',
      icon: Icons.people_outline,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _counterBtn(
              icon: Icons.remove,
              onTap: _guestsCount > 10 ? () => setState(() => _guestsCount -= 10) : null,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, primaryDark]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('$_guestsCount',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('ضيف', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            _counterBtn(
              icon: Icons.add,
              onTap: _guestsCount < 1000 ? () => setState(() => _guestsCount += 10) : null,
            ),
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
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: enabled ? primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: enabled ? primary : Colors.black26, size: 24),
      ),
    );
  }

  // ✅ قسم عرض الخدمات الديناميكية
  Widget _buildServicesSection() {
    return _buildSection(
      title: 'خدمات إضافية',
      icon: Icons.add_circle_outline,
      subtitle: '(اختياري)',
      child: Column(
        children: _availableServices.map((service) {
          final serviceName = service['name'] as String;
          final servicePrice = service['price'] as double;
          final selected = _selectedServices.contains(serviceName);
          
          return GestureDetector(
            onTap: () => setState(() {
              if (selected) {
                _selectedServices.remove(serviceName);
              } else {
                _selectedServices.add(serviceName);
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? primary : Colors.black.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primary.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(Icons.room_service, color: selected ? Colors.white : primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(serviceName,
                        style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                  ),
                  Text('${servicePrice.toStringAsFixed(0)} د.ل',
                      style: TextStyle(fontFamily: 'Tajawal', color: selected ? primary : textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? primary : Colors.black26, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Text(subtitle, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 11)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ✅ حساب الإجمالي مع الخدمات الديناميكية
  int _calculateTotal(int basePrice) {
    int servicesTotal = 0;
    for (final name in _selectedServices) {
      final service = _availableServices.firstWhere(
        (s) => s['name'] == name,
        orElse: () => {'price': 0.0},
      );
      servicesTotal += (service['price'] as double).toInt();
    }
    return basePrice + servicesTotal;
  }

  Widget _buildConfirmBar(int basePrice) {
    final total = _calculateTotal(basePrice);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي',
                    style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(text: '$total ',
                        style: const TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 22, fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'د.ل', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 13)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _confirmBooking(basePrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('تأكيد الحجز',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(int basePrice) async {
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('الرجاء تسجيل الدخول');
      return;
    }

    // ✅ التحقق من توفر الفترة في هذا التاريخ
    setState(() => _loading = true);
    try {
      final normalizedDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('hallId', isEqualTo: widget.hallId ?? '')
          .where('eventDate', isEqualTo: Timestamp.fromDate(normalizedDate))
          .where('timeSlot', isEqualTo: _selectedTimeSlot)
          .where('status', whereIn: ['pending', 'confirmed', 'checked_in'])
          .get();

      if (existingBookings.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showError('عذراً، هذه الفترة ($_selectedTimeSlot) محجوزة بالفعل في هذا التاريخ. الرجاء اختيار فترة أو تاريخ آخر.');
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('حدث خطأ أثناء التحقق من التوفر: $e');
      return;
    }

    setState(() => _loading = false);

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
            Text('دفع رسم الحجز', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لإتمام الحجز المبدئي، يجب دفع رسم حجز قدره:',
                style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('60 دينار ليبي',
                    style: TextStyle(fontFamily: 'Tajawal', color: primary, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'هذا المبلغ هو رسم حجز مبدئي للتطبيق فقط.\n\nسعر القاعة الكامل يُدفع نقداً لصاحب القاعة عند الحضور.',
              style: TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('يحق لك استرداد المبلغ كاملاً خلال 48 ساعة من الحجز',
                        style: TextStyle(fontFamily: 'Tajawal', color: Colors.orange, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('دفع 60 د.ل', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );

    if (shouldPay != true) return;

    setState(() => _loading = true);

    try {
      final total = _calculateTotal(basePrice);
      const double fixedCommission = 60.0;
      final expiresAt = DateTime.now().add(const Duration(hours: 48));
      
      final bookingDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);

      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'userId': uid,
        'hallId': widget.hallId ?? '',
        'hallName': widget.hallData['name'] ?? '',
        'hallImage': widget.hallData['image'] ?? widget.hallData['coverImage'] ?? '',
        'eventType': _selectedEventType,
        'timeSlot': _selectedTimeSlot,
        'eventDate': Timestamp.fromDate(bookingDate),
        'guestsCount': _guestsCount,
        'services': _selectedServices, // ✅ حفظ الخدمات المختارة
        'basePrice': basePrice,
        'totalPrice': total,
        'commission': fixedCommission,
        'providerNet': total,
        'status': 'confirmed',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'refundEligibleUntil': Timestamp.fromDate(expiresAt),
      });

      await bookingRef.update({'paymentStatus': 'commission_paid'});

      try {
        final hallDoc = await FirebaseFirestore.instance.collection('halls').doc(widget.hallId).get();
        final providerId = hallDoc.data()?['providerId'] ?? '';
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final customerName = userDoc.data()?['fullName'] ?? 'زبون';

        if (providerId.toString().isNotEmpty) {
          await NotificationHelper.notifyProviderNewBooking(
            providerId: providerId.toString(),
            hallName: widget.hallData['name'] ?? 'قاعة',
            customerName: customerName,
            bookingId: bookingRef.id,
          );
        }
      } catch (notifError) {}

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
              Text('تم الحجز بنجاح!', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18)),
            ],
          ),
          content: Text(
            'تم دفع رسم الحجز بنجاح (60 د.ل).\n\n'
            'لديك 48 ساعة للتوجه إلى "${widget.hallData['name'] ?? 'القاعة'}" ودفع سعر القاعة كاملاً ($total د.ل).\n\n'
            'خلال هذه المدة يمكنك إلغاء الحجز واسترداد 60 د.ل كاملة من "حجوزاتي".',
            style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 14, height: 1.6),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal')),
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
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.redAccent),
    );
  }
}
