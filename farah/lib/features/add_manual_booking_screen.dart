import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddManualBookingScreen extends StatefulWidget {
  const AddManualBookingScreen({super.key});

  @override
  State<AddManualBookingScreen> createState() => _AddManualBookingScreenState();
}

class _AddManualBookingScreenState extends State<AddManualBookingScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _selectedHallId;
  String? _selectedHallName;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRange = false;

  final Set<String> _selectedTimeSlots = {};
  String? _selectedEventType;

  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _hallsFuture;

  static const List<String> _timeSlots = [
    'الفترة الصباحية',
    'الفترة العصرية',
    'الفترة المسائية',
  ];

  static const List<String> _eventTypes = [
    'حفل زفاف',
    'محضر',
    'عقد قران',
    'أسبوع',
    'حفل تخرج',
    'فضانية',
    'حجز مسبق',
  ];

  @override
  void initState() {
    super.initState();
    _hallsFuture = _loadProviderHalls();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadProviderHalls() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final List<Map<String, dynamic>> halls = [];
    for (final field in ['providerId', 'ownerId', 'userId']) {
      final snap = await FirebaseFirestore.instance
          .collection('halls')
          .where(field, isEqualTo: uid)
          .get();
      if (snap.docs.isNotEmpty) {
        for (final doc in snap.docs) {
          halls.add({
            'id': doc.id,
            'name': doc.data()['name'] ?? 'قاعة',
          });
        }
        break;
      }
    }
    return halls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('إضافة حجز يدوي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hallsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          final halls = snap.data ?? [];
          if (halls.isEmpty) {
            return _buildNoHalls();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildIntroCard(),
                const SizedBox(height: 14),
                _buildHallSelector(halls),
                const SizedBox(height: 14),
                _buildDateSection(),
                const SizedBox(height: 14),
                _buildTimeSlotsSection(),
                const SizedBox(height: 14),
                _buildEventTypeSection(),
                const SizedBox(height: 14),
                _buildCustomerInfoSection(),
                const SizedBox(height: 14),
                _buildNotesSection(),
                const SizedBox(height: 20),
                _buildSaveButton(),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoHalls() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined, size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد قاعات مسجلة',
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('يجب إضافة قاعة أولاً قبل إضافة حجوزات يدوية',
                style: TextStyle(color: textLight, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'استخدم هذه الشاشة لإدخال الحجوزات الموجودة لديك مسبقاً (قبل استخدام التطبيق). هذه الحجوزات ستُغلق تواريخها في التطبيق تلقائياً.',
              style: TextStyle(color: textDark, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: primary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(title, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildHallSelector(List<Map<String, dynamic>> halls) {
    return _buildSection(
      title: 'القاعة',
      icon: Icons.storefront_outlined,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedHallId,
            hint: const Text('اختر القاعة', style: TextStyle(color: textLight, fontSize: 13)),
            items: halls.map((hall) {
              return DropdownMenuItem<String>(
                value: hall['id'] as String,
                child: Text(hall['name'] as String,
                    style: const TextStyle(color: textDark, fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedHallId = val;
                _selectedHallName = halls.firstWhere((h) => h['id'] == val)['name'];
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return _buildSection(
      title: 'التاريخ',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          // ── تبديل: يوم واحد / نطاق ──
          Row(
            children: [
              Expanded(
                child: _toggleOption(
                  label: 'يوم واحد',
                  icon: Icons.today,
                  selected: !_isRange,
                  onTap: () => setState(() {
                    _isRange = false;
                    _endDate = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggleOption(
                  label: 'نطاق تواريخ',
                  icon: Icons.date_range,
                  selected: _isRange,
                  onTap: () => setState(() => _isRange = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── حقل البداية ──
          GestureDetector(
            onTap: () => _pickDate(isStart: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _startDate != null ? primary.withValues(alpha: 0.08) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _startDate != null ? primary.withValues(alpha: 0.4) : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _startDate != null
                          ? (_isRange ? 'من: ' : '') + DateFormat('d MMMM yyyy', 'ar').format(_startDate!)
                          : 'اختر تاريخ البداية',
                      style: TextStyle(
                        color: _startDate != null ? textDark : textLight,
                        fontSize: 13,
                        fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: textLight, size: 18),
                ],
              ),
            ),
          ),

          // ── حقل النهاية (إذا كان نطاق) ──
          if (_isRange) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _pickDate(isStart: false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _endDate != null ? primary.withValues(alpha: 0.08) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _endDate != null ? primary.withValues(alpha: 0.4) : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _endDate != null
                            ? 'إلى: ${DateFormat('d MMMM yyyy', 'ar').format(_endDate!)}'
                            : 'اختر تاريخ النهاية',
                        style: TextStyle(
                          color: _endDate != null ? textDark : textLight,
                          fontSize: 13,
                          fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: textLight, size: 18),
                  ],
                ),
              ),
            ),
          ],

          // ── معاينة عدد الأيام ──
          if (_startDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isRange && _endDate != null
                        ? 'عدد الأيام: ${_endDate!.difference(_startDate!).inDays + 1}'
                        : 'يوم واحد',
                    style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [primary, primaryDark]) : null,
          color: selected ? null : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : textDark, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return _buildSection(
      title: 'الفترة الزمنية',
      icon: Icons.access_time,
      child: Column(
        children: [
          // ── زر اختيار كل الفترات ──
          GestureDetector(
            onTap: () {
              setState(() {
                if (_selectedTimeSlots.length == _timeSlots.length) {
                  _selectedTimeSlots.clear();
                } else {
                  _selectedTimeSlots.addAll(_timeSlots);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedTimeSlots.length == _timeSlots.length
                    ? primary.withValues(alpha: 0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedTimeSlots.length == _timeSlots.length
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('كل الفترات',
                      style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_selectedTimeSlots.length}/${_timeSlots.length}',
                      style: const TextStyle(color: textLight, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── الفترات الفردية ──
          ..._timeSlots.map((slot) {
            final selected = _selectedTimeSlots.contains(slot);
            final icons = {
              'الفترة الصباحية': Icons.wb_sunny_outlined,
              'الفترة العصرية': Icons.wb_twilight_outlined,
              'الفترة المسائية': Icons.nightlight_round_outlined,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedTimeSlots.remove(slot);
                    } else {
                      _selectedTimeSlots.add(slot);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? primary.withValues(alpha: 0.1) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icons[slot] ?? Icons.access_time,
                          color: selected ? primary : textLight, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(slot,
                            style: TextStyle(
                                color: selected ? primary : textDark,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500)),
                      ),
                      Icon(
                        selected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: selected ? primary : Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEventTypeSection() {
    return _buildSection(
      title: 'نوع المناسبة (اختياري)',
      icon: Icons.celebration_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _eventTypes.map((type) {
          final selected = _selectedEventType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedEventType = selected ? null : type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? const LinearGradient(colors: [primary, primaryDark]) : null,
                color: selected ? null : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: selected ? Colors.white : textDark,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return _buildSection(
      title: 'بيانات العميل (اختياري)',
      icon: Icons.person_outline,
      child: Column(
        children: [
          TextField(
            controller: _customerNameCtrl,
            textAlign: TextAlign.right,
            style: const TextStyle(color: textDark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'اسم العميل',
              hintStyle: const TextStyle(color: textLight, fontSize: 12),
              prefixIcon: const Icon(Icons.person_outline, color: primary, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _customerPhoneCtrl,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.right,
            style: const TextStyle(color: textDark, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'رقم هاتف العميل',
              hintStyle: const TextStyle(color: textLight, fontSize: 12),
              prefixIcon: const Icon(Icons.phone_outlined, color: primary, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'ملاحظات (اختياري)',
      icon: Icons.notes_outlined,
      child: TextField(
        controller: _notesCtrl,
        maxLines: 3,
        textAlign: TextAlign.right,
        style: const TextStyle(color: textDark, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'أي تفاصيل إضافية عن الحجز...',
          hintStyle: const TextStyle(color: textLight, fontSize: 12),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveManualBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('حفظ الحجز اليدوي',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 📅 اختيار التاريخ
  // ═══════════════════════════════════════════════════════════
  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 💾 حفظ الحجز اليدوي
  // ═══════════════════════════════════════════════════════════
  Future<void> _saveManualBooking() async {
    // التحقق
    if (_selectedHallId == null) {
      _showError('الرجاء اختيار القاعة');
      return;
    }
    if (_startDate == null) {
      _showError('الرجاء اختيار تاريخ البداية');
      return;
    }
    if (_isRange && _endDate == null) {
      _showError('الرجاء اختيار تاريخ النهاية');
      return;
    }
    if (_selectedTimeSlots.isEmpty) {
      _showError('الرجاء اختيار فترة زمنية واحدة على الأقل');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('الرجاء تسجيل الدخول');
      return;
    }

    setState(() => _loading = true);

    try {
      // حساب قائمة التواريخ
      final List<DateTime> dates = [];
      if (_isRange && _endDate != null) {
        DateTime current = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        while (!current.isAfter(end)) {
          dates.add(current);
          current = current.add(const Duration(days: 1));
        }
      } else {
        dates.add(DateTime(_startDate!.year, _startDate!.month, _startDate!.day));
      }

      // إنشاء حجز لكل (تاريخ × فترة)
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final date in dates) {
        for (final slot in _selectedTimeSlots) {
          final ref = FirebaseFirestore.instance.collection('bookings').doc();
          batch.set(ref, {
            'userId': 'manual_$uid',
            'hallId': _selectedHallId,
            'hallName': _selectedHallName ?? '',
            'hallImage': '',
            'eventType': _selectedEventType ?? 'حجز مسبق',
            'timeSlot': slot,
            'eventDate': Timestamp.fromDate(date),
            'guestsCount': 0,
            'basePrice': 0,
            'totalPrice': 0,
            'commission': 0.0,
            'providerNet': 0,
            'status': 'confirmed',
            'paymentStatus': 'paid',
            'isManual': true,
            'customerName': _customerNameCtrl.text.trim().isEmpty
                ? null
                : _customerNameCtrl.text.trim(),
            'customerPhone': _customerPhoneCtrl.text.trim().isEmpty
                ? null
                : _customerPhoneCtrl.text.trim(),
            'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }

      await batch.commit();

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
              Text('تم بنجاح!', style: TextStyle(color: textDark, fontSize: 18)),
            ],
          ),
          content: Text(
            'تم إضافة $count حجزاً يدوياً بنجاح.\n\n'
            'التواريخ المضافة أصبحت الآن محجوزة ولن تظهر للزبائن كأيام متاحة.',
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
      Navigator.pop(context, true);
    } catch (e) {
      _showError('فشل الحفظ: $e');
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
