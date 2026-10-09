import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReviewScreen extends StatefulWidget {
  final String hallId;
  final String hallName;
  final String? existingReviewId;

  const AddReviewScreen({
    super.key,
    required this.hallId,
    required this.hallName,
    this.existingReviewId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة تعليق'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      // ── جلب اسم المستخدم ──
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['fullName'] ??
          userDoc.data()?['name'] ??
          'مستخدم';

      // ── إضافة أو تحديث المراجعة ──
      await FirebaseFirestore.instance.collection('reviews').add({
        'hallId': widget.hallId,
        'userId': user.uid,
        'userName': userName,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── تحديث متوسط تقييم القاعة ──
      await _updateHallRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إضافة تقييمك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── حساب متوسط التقييم وتحديث القاعة ──
  Future<void> _updateHallRating() async {
    final reviewsSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('hallId', isEqualTo: widget.hallId)
        .get();

    if (reviewsSnap.docs.isEmpty) return;

    double total = 0;
    for (final doc in reviewsSnap.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }
    final avg = total / reviewsSnap.docs.length;

    await FirebaseFirestore.instance
        .collection('halls')
        .doc(widget.hallId)
        .update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewsCount': reviewsSnap.docs.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('إضافة تقييم',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── اسم القاعة ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [primary, primaryDark]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.celebration,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('أنت تقيّم',
                              style: TextStyle(
                                  color: textLight, fontSize: 11)),
                          const SizedBox(height: 3),
                          Text(
                            widget.hallName,
                            style: const TextStyle(
                                color: textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── التقييم بالنجوم ──
              const Text('تقييمك',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final active = i < _rating;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = i + 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              active ? Icons.star : Icons.star_border,
                              color: active
                                  ? Colors.amber
                                  : Colors.grey.withValues(alpha: 0.4),
                              size: 48,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ratingText(_rating),
                      style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── التعليق ──
              const Text('تعليقك',
                  style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _commentCtrl,
                  maxLines: 5,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'شاركنا تجربتك في هذه القاعة...',
                    hintStyle: TextStyle(
                        color: textLight.withValues(alpha: 0.7),
                        fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ── زر الإرسال ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 20),
                            SizedBox(width: 10),
                            Text('نشر التقييم',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingText(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }
}
