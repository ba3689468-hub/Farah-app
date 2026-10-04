import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../auth/presentation/screens/login_screen_farah.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?q=80&w=1000&auto=format&fit=crop',
      'title': 'مرحباً بك في تطبيق فرح',
      'desc': 'أكبر دليل لحجز قاعات الأفراح في ليبيا - تصفح القاعات، قارن الأسعار، واحجز بكل سهولة',
    },
    {
      'image': 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=1000&auto=format&fit=crop',
      'title': 'تصفح القاعات',
      'desc': 'اكتشف أفضل القاعات والمزودين حسب المدينة والسعر والتقييم',
    },
    {
      'image': 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?q=80&w=1000&auto=format&fit=crop',
      'title': 'قارن الأسعار',
      'desc': 'شاهد الصور، التقييمات، والأسعار لاتخاذ القرار الأفضل لقاعتك',
    },
    {
      'image': 'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?q=80&w=1000&auto=format&fit=crop',
      'title': 'احجز بسهولة',
      'desc': 'اختر تاريخك، حدد عدد الضيوف، وأتمم حجزك في دقائق معدودة',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FarahGlassLoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── الجزء العلوي: الخلفية الوردية المتدرجة ──
          Container(
            height: size.height * 0.70, // زيادة الارتفاع قليلاً
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.4),
                  Colors.white,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // ── زر تخطي (أعلى اليسار) ──
          Positioned(
            top: 40,
            left: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarahGlassLoginScreen(),
                  ),
                );
              },
              child: const Text(
                'تخطي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── عرض الصفحات (PageView) - تم تكبيرها ──
          Positioned(
            top: size.height * 0.08, // رفع القوس للأعلى
            left: 0,
            right: 0,
            height: size.height * 0.62, // زيادة الارتفاع
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildArchPage(_pages[index], index);
              },
            ),
          ),

          // ── الجزء السفلي: النصوص والأزرار ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── نقاط التقدم (Dots) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index == _currentIndex),
                    ),
                  ),
                  const SizedBox(height: 20), // تقليل المسافة

                  // ── النصوص المتغيرة مع الانيميشن ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey<int>(_currentIndex),
                      children: [
                        Text(
                          _pages[_currentIndex]['title']!,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24, // تصغير الخط قليلاً للتناسق
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _pages[_currentIndex]['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13, // تصغير الخط قليلاً
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25), // تقليل المسافة

                  // ── زر التالي / ابدأ الآن ──
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentIndex == _pages.length - 1 ? 160 : 120,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentIndex == _pages.length - 1
                              ? 'ابدأ الآن'
                              : 'التالي',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // مسافة أخيرة
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── دالة لبناء القوس مع الصورة والانيميشن (تم تكبير الأبعاد) ──
  Widget _buildArchPage(Map<String, String> page, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: Transform.scale(
            scale: Curves.easeOutCubic.transform(value),
            child: Container(
              // ✅ زيادة العرض والارتفاع لجعل الصورة أكبر
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 3, // إطار أسمك قليلاً
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(250), // قوس أكبر
                  topRight: Radius.circular(250), // قوس أكبر
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(250),
                  topRight: Radius.circular(250),
                ),
                child: Image.network(
                  page['image']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      child: const Center(
                        child: Icon(
                          Icons.celebration,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
