import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:farah/core/constants/app_colors.dart';

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
  static const Color bgColor = Color(0xFFF9F9FB);

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  
  // ✅ متغير الفلترة
  String _filter = 'all'; 

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'محفظتي',
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: primary));
          
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final balance = (userData?['walletBalance'] ?? 0).toDouble();

          return Column(
            children: [
              // 1. بطاقة الرصيد
              _buildBalanceCard(balance),

              // 2. الملخص السريع (إيداعات / مدفوعات)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('userId', isEqualTo: _uid)
                    .snapshots(),
                builder: (context, txSnapshot) {
                  double totalDeposits = 0;
                  double totalPayments = 0;
                  
                  if (txSnapshot.hasData) {
                    for (var doc in txSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = (data['amount'] ?? 0).toDouble();
                      final type = data['type'] ?? '';
                      
                      if (type == 'deposit' || type == 'refund') {
                        totalDeposits += amount;
                      } else if (type == 'payment') {
                        totalPayments += amount;
                      }
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildSummaryCard('إجمالي الإيداعات', totalDeposits, Colors.green),
                        const SizedBox(width: 12),
                        _buildSummaryCard('إجمالي المدفوعات', totalPayments, Colors.redAccent),
                      ],
                    ),
                  );
                },
              ),

              // 3. الفلاتر
              _buildFilterTabs(),

              // 4. قائمة المعاملات
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('userId', isEqualTo: _uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: primary));
                    }
                    
                    final allTransactions = snapshot.data?.docs ?? [];
                    
                    // تطبيق الفلترة
                    final transactions = allTransactions.where((doc) {
                      if (_filter == 'all') return true;
                      final type = (doc.data() as Map)['type'] ?? '';
                      return type == _filter;
                    }).toList();

                    if (transactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    transactions.sort((a, b) {
                      final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                      final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                      if (aT == null || bT == null) return 0;
                      return bT.compareTo(aT);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        final tx = transactions[i].data() as Map<String, dynamic>;
                        return _buildTransactionCard(tx);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── بطاقة الرصيد ──
  Widget _buildBalanceCard(double balance) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40, left: -40,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08))),
          ),
          Positioned(
            bottom: -50, right: -20,
            child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('الرصيد الحالي', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(balance.toStringAsFixed(2), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('د.ل', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddBalanceDialog(balance),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('إضافة رصيد', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── بطاقات الملخص السريع ──
  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              '${amount.toStringAsFixed(0)} د.ل',
              style: TextStyle(fontFamily: 'Tajawal', color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── الفلاتر ──
  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt_rounded},
      {'key': 'deposit', 'label': 'إيداعات', 'icon': Icons.arrow_downward_rounded},
      {'key': 'refund', 'label': 'استردادات', 'icon': Icons.replay_rounded},
      {'key': 'payment', 'label': 'مدفوعات', 'icon': Icons.arrow_upward_rounded},
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final t = tabs[i];
          final active = t['key'] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = t['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? primary : Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, color: active ? Colors.white : textLight, size: 16),
                  const SizedBox(width: 6),
                  Text(t['label'] as String, style: TextStyle(fontFamily: 'Tajawal', color: active ? Colors.white : textDark, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── بطاقة المعاملة ──
  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final type = tx['type'] ?? 'deposit';
    final description = tx['description'] ?? 'معاملة';
    final date = tx['createdAt'] is Timestamp ? (tx['createdAt'] as Timestamp).toDate() : DateTime.now();

    Color color = Colors.green;
    IconData icon = Icons.arrow_downward_rounded;
    String sign = '+';
    String typeText = 'إيداع';

    if (type == 'payment') {
      color = Colors.redAccent;
      icon = Icons.arrow_upward_rounded;
      sign = '-';
      typeText = 'دفع';
    } else if (type == 'refund') {
      color = Colors.blue;
      icon = Icons.replay_rounded;
      typeText = 'استرداد';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(typeText, style: TextStyle(fontFamily: 'Tajawal', color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormat('yyyy/MM/dd - hh:mm a').format(date), style: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$sign${amount.toStringAsFixed(0)} د.ل',
            style: TextStyle(fontFamily: 'Tajawal', color: color, fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 60, color: primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          const Text('لا توجد معاملات في هذا القسم', style: TextStyle(fontFamily: 'Tajawal', color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddBalanceDialog(double currentBalance) {
    final TextEditingController amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text('إضافة رصيد', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: textDark, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل المبلغ الذي تريد إضافته:', style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: textLight)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'مثال: 100',
                hintStyle: const TextStyle(fontFamily: 'Tajawal', color: textLight, fontWeight: FontWeight.normal),
                filled: true,
                fillColor: bgColor,
                prefixIcon: const Icon(Icons.attach_money_rounded, color: primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: textLight))),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                await _addBalance(amount, currentBalance);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addBalance(double amount, double currentBalance) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'walletBalance': currentBalance + amount,
      });

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': _uid,
        'amount': amount,
        'type': 'deposit',
        'description': 'إضافة رصيد للمحفظة',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت إضافة الرصيد بنجاح', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e', style: TextStyle(fontFamily: 'Tajawal')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
