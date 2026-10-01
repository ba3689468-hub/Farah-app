import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFF999999);

  final _pageCtrl = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'icon': Icons.celebration,
      'title': 'مرحباً بك في فرح',
      'desc': 'وجهتك الأولى لحجز صالات الأفراح والمناسبات في جميع المدن الليبية',
    },
    {
      'icon': Icons.storefront,
      'title': 'تصفّح واختر',
      'desc': 'اكتشف أفضل القاعات والمزوّدين حسب المدينة والسعر والتقييم',
    },
    {
      'icon': Icons.event_available,
      'title': 'احجز بسهولة',
      'desc': 'اختر تاريخك وعدد الضيوف وأتمم حجزك في دقائق',
    },
    {
      'icon': Icons.verified_user,
      'title': 'دفع آمن',
      'desc': 'ادفع إلكترونياً أو بعربون أو عند الحضور — بكل سهولة وأمان',
    },
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgLight, Colors.white, Color(0xFFFFF5F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // زر تخطي
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('تخطي',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      )),
                  ),
                ),
              ),
              // الصفحات
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
                            width: 180, height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [primary, primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.4),
                                  blurRadius: 45,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(p['icon'] as IconData,
                              size: 85, color: Colors.white),
                          ),
                          const SizedBox(height: 50),
                          Text(p['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            )),
                          const SizedBox(height: 14),
                          Text(p['desc'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: textLight,
                              height: 1.7,
                            )),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // مؤشرات
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
                      gradient: active
                          ? const LinearGradient(colors: [primary, primaryDark])
                          : null,
                      color: active ? null : primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),
              // زر متابعة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      shadowColor: primary.withOpacity(0.4),
                    ),
                    child: Text(
                      _current == _pages.length - 1 ? 'ابدأ الآن' : 'متابعة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
