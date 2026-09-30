import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const Color gold      = Color(0xFFC0392B);
  static const Color lightGold = Color(0xFFA93226);
  static const Color chocolate = Color(0xFFC0392B);

  final List<Map<String, dynamic>> _pages = const [
    {'icon': Icons.celebration, 'title': 'مرحباً بك في فرح', 'desc': 'وجهتك الأولى لحجز صالات الأفراح والمناسبات في جميع المدن الليبية'},
    {'icon': Icons.storefront, 'title': 'تصفح واختر', 'desc': 'اكتشف أفضل القاعات والمزودين حسب المدينة والسعر والتقييم'},
    {'icon': Icons.event_available, 'title': 'احجز بسهولة', 'desc': 'اختر تاريخك وعدد الضيوف وأتمم حجزك في دقائق'},
    {'icon': Icons.verified_user, 'title': 'دفع آمن', 'desc': 'ادفع إلكترونياً أو بعربون أو عند الحضور — بكل سهولة وأمان'},
  ];

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: widget.onFinish,
                  child: const Text('تخطي',
                    style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 170, height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [gold, lightGold],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: gold.withOpacity(0.35), blurRadius: 40, spreadRadius: 5),
                            ],
                          ),
                          child: Icon(p['icon'] as IconData, size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 45),
                        Text(p['title'] as String,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: chocolate)),
                        const SizedBox(height: 14),
                        Text(p['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Color(0xFF6B5B57), height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 30 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: active ? gold : gold.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_current == _pages.length - 1) {
                      widget.onFinish();
                    } else {
                      _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text(
                    _current == _pages.length - 1 ? 'ابدأ الآن' : 'متابعة',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}
