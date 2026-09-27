import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hallData;
  const HallDetailsScreen({super.key, required this.hallData});

  @override
  State<HallDetailsScreen> createState() => _HallDetailsScreenState();
}

class _HallDetailsScreenState extends State<HallDetailsScreen> {
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('bookings').add({
        'userEmail': user?.email ?? 'غير معروف',
        'hallName': widget.hallData['name'] ?? 'قاعة',
        'hallPrice': widget.hallData['price'] ?? 0,
        'bookingDate': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد حجزك وحفظه بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحجز: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hallData['name'] ?? 'تفاصيل القاعة'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.hallData['image'] ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 80)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.hallData['name'] ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(widget.hallData['location'] ?? '', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text('${widget.hallData['price']} دينار', style: const TextStyle(fontSize: 24, color: Colors.pink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  const Text('تفاصيل إضافية:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('هذه القاعة مجهزة بأحدث التقنيات وتتسع لأعداد كبيرة. يمكنك الحجز الآن والاستمتاع بخصم خاص.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _isLoading ? null : _confirmBooking,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('تأكيد الحجز', style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
