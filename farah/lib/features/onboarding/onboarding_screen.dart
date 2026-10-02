import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
// ⚠️ تأكد من مسار ملف شاشة الدخول الصحيح هنا (login_screen_farah.dart أو login_screen.dart)
import '../../auth/presentation/screens/login_screen.dart'; 

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  final _pageCtrl = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'icon': Icons.celebration,
      'title': 'مرحباً بك في فرح',
      'desc': 'وجهتك الأولى لحجز صالات الأفراح والمناسبات في جميع المدن الليبية.',
    },
    {
      'icon': Icons.storefront,
      'title': 'اكتشف وأقارن',
      'desc': 'اكتشف أفضل القاعات والمزودين حسب المدينة والسعر والتقييم.',
    },
    {
      'icon': Icons.event_available,
      'title': 'احجز بسهولة',
      'desc': 'اختر تاريخك وحدد الضيوف وأتمم حجزك في دقائق.',
    },
    {
      'icon': Icons.verified_user,
      'title': 'ادفع بآمان',
      'desc': 'ادفع إلكترونياً أو عند الحضور — بكل سهولة وأمان.',
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
        color: AppColors.softBackground,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                    onPressed: () {
                      widget.onFinish();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          // ✅ تم إزالة const من هنا
                          builder: (_) => FarahGlassLoginScreen(),
                        ),
                      );
                    },
                    child: const Text('تخطي',
                        style: TextStyle(color: textLight, fontSize: 14)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(p['icon'] as IconData,
                                size: 70, color: Colors.white),
                          ),
                          const SizedBox(height: 40),
                          Text(p['title'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: textDark,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text(p['desc'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: textLight,
                                  fontSize: 14,
                                  height: 1.6)),
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
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? primary : primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_current == _pages.length - 1) {
                        widget.onFinish();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            // ✅ تم إزالة const من هنا
                            builder: (_) => FarahGlassLoginScreen(),
                          ),
                        );
                      } else {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text(
                      _current == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
