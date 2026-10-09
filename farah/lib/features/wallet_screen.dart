import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  late Future<Map<String, dynamic>> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _loadWalletData();
  }

  Future<Map<String, dynamic>> _loadWalletData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'no user';

    // ── بيانات المستخدم ──
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    // ── الحجوزات ──
    final bookingsSnap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .get();

    int totalPaid = 0;
    int totalPending = 0;
    int totalRefunded = 0;
    final List<Map<String, dynamic>> transactions = [];

    for (final doc in bookingsSnap.docs) {
      final data = doc.data();
      final total = (data['totalPrice'] ?? 0) is int
          ? (data['totalPrice'] as int)
          : int.tryParse(data['totalPrice'].toString()) ?? 0;
      final status = data['status'] ?? 'pending';
      final paymentStatus = data['paymentStatus'] ?? 'unpaid';
      final hallName = data['hallName'] ?? 'قاعة';
      final createdAt = data['createdAt'] as Timestamp?;

      if (paymentStatus == 'paid') {
        totalPaid += total;
      } else if (status == 'cancelled') {
        totalRefunded += total;
      } else {
        totalPending += total;
      }

      transactions.add({
        'type': 'booking',
        'title': 'حجز $hallName',
        'amount': total,
        'status': status,
        'paymentStatus': paymentStatus,
        'date': createdAt,
      });
    }

    // ── ترتيب حسب التاريخ ──
    transactions.sort((a, b) {
      final aT = a['date'] as Timestamp?;
      final bT = b['date'] as Timestamp?;
      if (aT == null && bT == null) return 0;
      if (aT == null) return 1;
      if (bT == null) return -1;
      return bT.compareTo(aT);
    });

    return {
      'balance': userData['walletBalance'] ?? 0,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'totalRefunded': totalRefunded,
      'bookingsCount': bookingsSnap.docs.length,
      'transactions': transactions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text('محفظتي',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: textDark)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _walletFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: primary));
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 60, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text('تعذر تحميل المحفظة',
                        style: TextStyle(color: textDark)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _walletFuture = _loadWalletData();
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('حاول مرة أخرى'),
                    ),
                  ],
                ),
              );
            }

            final data = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── بطاقة الرصيد ──
                  _buildBalanceCard(data['balance'] ?? 0),
                  const SizedBox(height: 16),

                  // ── الإحصائيات ──
                  _buildStats(data),
                  const SizedBox(height: 20),

                  // ── أزرار الإجراءات ──
                  _buildActions(),
                  const SizedBox(height: 24),

                  // ── المعاملات ──
                  _buildTransactionsSection(
                      data['transactions'] as List<Map<String, dynamic>>),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── بطاقة الرصيد ──
  Widget _buildBalanceCard(int balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [primary, primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── دوائر زخرفية ──
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Text('الرصيد الحالي',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('د.ل',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                balance == 0
                    ? 'رصيدك فارغ حالياً'
                    : 'متاح للاستخدام',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── الإحصائيات ──
  Widget _buildStats(Map<String, dynamic> data) {
    return Row(
      children: [
        _statCard(
          Icons.arrow_downward,
          'مدفوع',
          '${data['totalPaid'] ?? 0}',
          Colors.green,
        ),
        const SizedBox(width: 10),
        _statCard(
          Icons.hourglass_bottom,
          'معلق',
          '${data['totalPending'] ?? 0}',
          Colors.orange,
        ),
        const SizedBox(width: 10),
        _statCard(
          Icons.replay,
          'مسترجع',
          '${data['totalRefunded'] ?? 0}',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _statCard(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: textLight, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── أزرار الإجراءات ──
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            Icons.add_circle_outline,
            'إضافة رصيد',
            primary,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً: إضافة رصيد'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            Icons.receipt_long_outlined,
            'الفواتير',
            primaryDark,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً: الفواتير'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            Icons.help_outline,
            'الدعم',
            const Color(0xFF9C27B0),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('قريباً: الدعم'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── قسم المعاملات ──
  Widget _buildTransactionsSection(
      List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('سجل المعاملات',
                style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${transactions.length}',
                style: const TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 60, color: textLight),
                SizedBox(height: 12),
                Text('لا توجد معاملات بعد',
                    style: TextStyle(color: textDark, fontSize: 14)),
              ],
            ),
          )
        else
          ...transactions.map((t) => _buildTransactionItem(t)).toList(),
      ],
    );
  }

  // ── عنصر معاملة ──
  Widget _buildTransactionItem(Map<String, dynamic> t) {
    final title = t['title'] ?? 'معاملة';
    final amount = t['amount'] ?? 0;
    final status = t['status'] ?? 'pending';
    final paymentStatus = t['paymentStatus'] ?? 'unpaid';
    final date = t['date'] as Timestamp?;

    // ── لون وأيقونة حسب الحالة ──
    Color color;
    IconData icon;
    String statusLabel;

    if (paymentStatus == 'paid') {
      color = Colors.green;
      icon = Icons.check_circle;
      statusLabel = 'مدفوع';
    } else if (status == 'cancelled') {
      color = Colors.blue;
      icon = Icons.replay;
      statusLabel = 'مسترجع';
    } else if (status == 'completed') {
      color = Colors.green;
      icon = Icons.done_all;
      statusLabel = 'مكتمل';
    } else {
      color = Colors.orange;
      icon = Icons.access_time;
      statusLabel = 'معلق';
    }

    final dateStr = date != null
        ? DateFormat('yyyy/MM/dd').format(date.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(dateStr,
                        style: const TextStyle(
                            color: textLight, fontSize: 11)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text('$amount د.ل',
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
