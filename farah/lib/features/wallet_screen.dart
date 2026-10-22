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

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Center(child: Text('يجب تسجيل الدخول'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('محفظتي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ✅ بطاقة الرصيد
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final balance = (data?['walletBalance'] ?? 0).toDouble();

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
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          balance.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('د.ل', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBalanceDialog(balance),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('إضافة رصيد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ✅ عنوان سجل المعاملات
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('سجل المعاملات', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // ✅ قائمة المعاملات
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
                
                final transactions = snapshot.data?.docs ?? [];
                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                // ترتيب المعاملات من الأحدث للأقدم
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
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = (tx['amount'] ?? 0).toDouble();
    final type = tx['type'] ?? 'deposit'; // deposit, refund, payment
    final description = tx['description'] ?? 'معاملة';
    final date = tx['createdAt'] is Timestamp ? (tx['createdAt'] as Timestamp).toDate() : DateTime.now();

    Color color = Colors.green;
    IconData icon = Icons.arrow_downward;
    String sign = '+';

    if (type == 'payment') {
      color = Colors.redAccent;
      icon = Icons.arrow_upward;
      sign = '-';
    } else if (type == 'refund') {
      color = Colors.blue;
      icon = Icons.replay;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('yyyy/MM/dd - hh:mm a').format(date), style: const TextStyle(color: textLight, fontSize: 12)),
              ],
            ),
          ),
          Text(
            '$sign$amount د.ل',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
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
          Icon(Icons.receipt_long, size: 80, color: primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('لا توجد معاملات حتى الآن', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ✅ دالة إضافة رصيد (محاكاة)
  void _showAddBalanceDialog(double currentBalance) {
    final TextEditingController amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة رصيد', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل المبلغ الذي تريد إضافته (تجريبي):', style: TextStyle(fontSize: 13, color: textLight)),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'مثال: 100'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                await _addBalance(amount, currentBalance);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBalance(double amount, double currentBalance) async {
    try {
      // 1. تحديث الرصيد
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'walletBalance': currentBalance + amount,
      });

      // 2. إضافة سجل معاملة
      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': _uid,
        'amount': amount,
        'type': 'deposit',
        'description': 'إضافة رصيد للمحفظة',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت إضافة الرصيد بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
