import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('الرجاء تسجيل الدخول')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text('الإشعارات',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textDark)),
        centerTitle: true,
        actions: [
          // ── تحديد الكل كمقروء ──
          TextButton.icon(
            onPressed: () => _markAllAsRead(user.uid),
            icon: const Icon(Icons.done_all, color: primary, size: 18),
            label: const Text('تحديد الكل',
                style: TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
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
                    Text('حدث خطأ: ${snap.error}',
                        style: const TextStyle(
                            color: textDark, fontSize: 13)),
                  ],
                ),
              );
            }

            final notifs = snap.data?.docs ?? [];

            // ── ترتيب حسب التاريخ ──
            final sortedList = List<QueryDocumentSnapshot>.from(notifs);
            sortedList.sort((a, b) {
              final aT = (a.data() as Map)['createdAt'] as Timestamp?;
              final bT = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aT == null && bT == null) return 0;
              if (aT == null) return 1;
              if (bT == null) return -1;
              return bT.compareTo(aT);
            });

            if (sortedList.isEmpty) {
              return _buildEmpty();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedList.length,
              itemBuilder: (context, i) {
                final doc = sortedList[i];
                return _buildNotificationItem(
                    doc.data() as Map<String, dynamic>, doc.id);
              },
            );
          },
        ),
      ),
    );
  }

  // ── لا توجد إشعارات ──
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none,
                size: 70, color: primary),
          ),
          const SizedBox(height: 20),
          const Text('لا توجد إشعارات',
              style: TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('ستظهر هنا تنبيهات حجوزاتك',
              style: TextStyle(color: textLight, fontSize: 13)),
        ],
      ),
    );
  }

  // ── عنصر الإشعار ──
  Widget _buildNotificationItem(Map<String, dynamic> data, String docId) {
    final title = data['title'] ?? 'إشعار';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'info';
    final isRead = data['isRead'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;

    // ── أيقونة ولون حسب النوع ──
    IconData icon;
    Color color;

    switch (type) {
      case 'booking':
        icon = Icons.calendar_month;
        color = const Color(0xFF4CAF50);
        break;
      case 'review':
        icon = Icons.star;
        color = const Color(0xFFFFA726);
        break;
      case 'payment':
        icon = Icons.account_balance_wallet;
        color = const Color(0xFF3F51B5);
        break;
      case 'cancel':
        icon = Icons.cancel;
        color = Colors.redAccent;
        break;
      default:
        icon = Icons.info_outline;
        color = primary;
    }

    // ── التاريخ ──
    String dateStr = '';
    if (createdAt != null) {
      final d = createdAt.toDate();
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 60) {
        dateStr = 'منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inHours < 24) {
        dateStr = 'منذ ${diff.inHours} ساعة';
      } else if (diff.inDays < 7) {
        dateStr = 'منذ ${diff.inDays} يوم';
      } else {
        dateStr = '${d.year}/${d.month}/${d.day}';
      }
    }

    return GestureDetector(
      onTap: () {
        // ── تحديد كمقروء ──
        if (!isRead) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(docId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.black.withValues(alpha: 0.05)
                : primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── أيقونة ──
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
            // ── المحتوى ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textDark,
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                          color: textLight, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: textLight, size: 12),
                      const SizedBox(width: 3),
                      Text(dateStr,
                          style: const TextStyle(
                              color: textLight, fontSize: 10)),
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

  // ── تحديد الكل كمقروء ──
  Future<void> _markAllAsRead(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد الكل كمقروء'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }
}
