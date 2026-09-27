import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'core/constants/app_colors.dart';

class HallListScreen extends StatefulWidget {
  const HallListScreen({super.key});
  @override
  State<HallListScreen> createState() => _HallListScreenState();
}

class _HallListScreenState extends State<HallListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصالات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // ═══ استخدام FutureBuilder للاختبار ═══
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('halls').get(),
        builder: (context, snapshot) {
          // 1. في انتظار البيانات
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.goldPrimary),
                  SizedBox(height: 20),
                  Text('جاري الاتصال بـ Firestore...',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            );
          }

          // 2. حدث خطأ
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 80, color: Colors.red),
                    const SizedBox(height: 20),
                    const Text('خطأ:',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                    const SizedBox(height: 10),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
            );
          }

          // 3. نجح لكن لا توجد بيانات
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 80, color: AppColors.goldPrimary),
                  const SizedBox(height: 20),
                  const Text('المجموعة halls فارغة!',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('عدد المستندات: ${snapshot.data?.docs.length ?? 0}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          // 4. نجح ووجدنا بيانات
          final halls = snapshot.data!.docs;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.green,
                child: Text(
                  '✅ تم العثور على ${halls.length} قاعة',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: halls.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final hall =
                        halls[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: hall['image'] != null
                            ? Image.network(hall['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image, size: 60))
                            : const Icon(Icons.image, size: 60),
                        title: Text(hall['name'] ?? 'بدون اسم'),
                        subtitle: Text(hall['location'] ?? 'بدون موقع'),
                        trailing: Text('${hall['price']} دينار'),
                      ),
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
}
