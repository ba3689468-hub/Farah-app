import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  final String? hallId;
  const BookingScreen({super.key, required this.hallData, this.hallId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color primary = Color(0xFFC0392B);
  static const Color darkRed = Color(0xFFA93226);
  static const Color cream = Color(0xFFEDEEE9);
  static const Color chocolate = Color(0xFF3E3530);

  DateTime? _selectedDate;
  int _guestsCount = 50;
  final List<String> _selectedServices = [];
  bool _loading = false;

  final List<Map<String, dynamic>> _availableServices = const [
    {'name': 'خدمة الضيافة الكاملة', 'price': 500, 'icon': Icons.restaurant},
    {'name': 'تصوير احترافي', 'price': 800, 'icon': Icons.camera_alt},
    {'name': 'دي جي وموسيقى', 'price': 600, 'icon': Icons.music_note},
    {'name': 'تزيين القاعة', 'price': 1200, 'icon': Icons.auto_awesome},
    {'name': 'كوشة العروسين', 'price': 1500, 'icon': Icons.favorite},
    {'name': 'خدمة صف السيارات', 'price': 300, 'icon': Icons.local_parking},
  ];

  @override
  Widget build(BuildContext context) {
    final hall = widget.hallData;
    final name = hall['name'] ?? 'صالة';
    final basePrice = (hall['price'] ?? 0) is int
        ? hall['price'] as int
        : int.tryParse(hall['price'].toString()) ?? 0;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('حجز القاعة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHallSummary(name, basePrice),
            const SizedBox(height: 8),
            _buildDateSection(),
            _buildGuestsSection(),
            _buildServicesSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmBar(basePrice),
    );
  }

  Widget _buildHallSummary(String name, int basePrice) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, darkRed]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.celebration, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أنت تحجز في', style: TextStyle(color: Colors.black45, fontSize: 11)),
                const SizedBox(height: 3),
                Text(name, style: const TextStyle(color: chocolate, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: '$basePrice ',
                style: const TextStyle(color: primary, fontSize: 17, fontWeight: FontWeight.bold)),
              const TextSpan(text: 'د.ل', style: TextStyle(color: chocolate, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i + 1)));
    final dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('اختر التاريخ',
                style: TextStyle(color: chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected = _selectedDate != null &&
                    _selectedDate!.day == d.day &&
                    _selectedDate!.month == d.month;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 62,
                    decoration: BoxDecoration(
                      gradient: selected ? const LinearGradient(colors: [primary, darkRed]) : null,
                      color: selected ? null : cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? Colors.transparent : primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayNames[d.weekday % 7],
                          style: TextStyle(color: selected ? Colors.white70 : Colors.black45, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text('${d.day}', style: TextStyle(color: selected ? Colors.white : chocolate, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMM', 'en').format(d),
                          style: TextStyle(color: selected ? Colors.white70 : Colors.black45, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'التاريخ المختار: ${DateFormat('yyyy/MM/dd').format(_selectedDate!)}',
                    style: const TextStyle(color: chocolate, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_outline, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('عدد الضيوف',
                style: TextStyle(color: chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
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
                  gradient: const LinearGradient(colors: [primary, darkRed]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('$_guestsCount',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('ضيف', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              _counterBtn(
                icon: Icons.add,
                onTap: _guestsCount < 1000 ? () => setState(() => _guestsCount += 10) : null,
              ),
            ],
          ),
        ],
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
          color: enabled ? primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: enabled ? primary : Colors.black26, size: 24),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('خدمات إضافية',
                style: TextStyle(color: chocolate, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('(اختياري)', style: TextStyle(color: Colors.black45, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          ...(_availableServices.map((service) {
            final selected = _selectedServices.contains(service['name']);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedServices.remove(service['name']);
                } else {
                  _selectedServices.add(service['name'] as String);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? primary.withOpacity(0.08) : cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? primary : Colors.transparent,
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
                      ),
                      child: Icon(service['icon'] as IconData,
                        color: selected ? Colors.white : primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(service['name'] as String,
                        style: TextStyle(
                          color: chocolate,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        )),
                    ),
                    Text('${service['price']} د.ل',
                      style: TextStyle(
                        color: selected ? primary : chocolate,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      )),
                    const SizedBox(width: 8),
                    Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? primary : Colors.black26,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  int _calculateTotal(int basePrice) {
    int services = 0;
    for (final name in _selectedServices) {
      final service = _availableServices.firstWhere(
        (s) => s['name'] == name,
        orElse: () => {'price': 0},
      );
      services += service['price'] as int;
    }
    return basePrice + services;
  }

  Widget _buildConfirmBar(int basePrice) {
    final total = _calculateTotal(basePrice);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedServices.isNotEmpty || _selectedDate != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي',
                    style: TextStyle(color: chocolate, fontSize: 15, fontWeight: FontWeight.bold)),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '$total ',
                        style: const TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold)),
                      const TextSpan(text: 'د.ل', style: TextStyle(color: chocolate, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _confirmBooking(basePrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('تأكيد الحجز',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(int basePrice) async {
    if (_selectedDate == null) {
      _showError('الرجاء اختيار تاريخ الحجز');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('الرجاء تسجيل الدخول');
      return;
    }

    setState(() => _loading = true);

    try {
      final total = _calculateTotal(basePrice);
      final commission = (total * 0.1).round();
      final providerNet = total - commission;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': uid,
        'hallId': widget.hallId ?? '',
        'hallName': widget.hallData['name'] ?? '',
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'guestsCount': _guestsCount,
        'services': _selectedServices,
        'basePrice': basePrice,
        'totalPrice': total,
        'commission': commission,
        'providerNet': providerNet,
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: cream,
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('تم الحجز بنجاح', style: TextStyle(color: chocolate, fontSize: 18)),
            ],
          ),
          content: Text(
            'حجزك في ${widget.hallData['name'] ?? ''} قيد المراجعة من قبل المزوّد.\nسيتم إشعارك عند التأكيد.',
            style: const TextStyle(color: chocolate, fontSize: 14, height: 1.6),
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
}
