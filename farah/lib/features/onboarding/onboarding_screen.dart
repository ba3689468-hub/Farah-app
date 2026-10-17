import 'package:flutter/material.dart';
import 'package:farah/core/constants/app_colors.dart';
import '../auth/presentation/screens/login_screen_farah.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'مرحباً بك في تطبيق فرح',
      'subtitle': 'أكبر دليل لحجز قاعات الأفراح في ليبيا - تصفح القاعات، قارن الأسعار، واحجز بكل سهولة',
      'image': 'assets/images/onboarding1.png', // تأكد من وجود الصورة في هذا المسار
    },
    {
      'title': 'احجز قاعتك بضغطة زر',
      'subtitle': 'تصفح أفضل القاعات، اختر التاريخ والوقت المناسبين، واحجز بكل سهولة وأمان',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'خدمات متكاملة لحفلك',
      'subtitle': 'كل ما تحتاجه في مكان واحد: تصوير، ضيافة، ديكور، وفساتين أفراح',
      'image': 'assets/images/onboarding3.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إجبار الشاشة على العمل من اليسار لليمين (LTR) للحفاظ على التصميم الأصلي
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── زر التخطي (على اليسار كما طلبت) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _goToLogin(context),
                    child: const Text(
                      'تخطي',
                      style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              // ── محتوى الصفحات ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(
                      title: _pages[index]['title']!,
                      subtitle: _pages[index]['subtitle']!,
                      imagePath: _pages[index]['image']!,
                    );
                  },
                ),
              ),

              // ── المؤشرات (النقاط) وزر التالي ──
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // النقاط
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // زر التالي / ابدأ الآن
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _goToLogin(context);
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            // السهم يتجه لليمين دائماً في LTR
                            Icon(
                              _currentPage == _pages.length - 1 ? Icons.check : Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── دالة بناء الصفحة ──
  Widget _buildPage({required String title, required String subtitle, required String imagePath}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الصورة
          Expanded(
            flex: 3,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 80, color: AppColors.primary),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          
          // العنوان
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // الوصف
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── دالة بناء النقاط (المؤشرات) ──
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── الانتقال لصفحة تسجيل الدخول ──
  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FarahGlassLoginScreen()),
    );
  }
}
