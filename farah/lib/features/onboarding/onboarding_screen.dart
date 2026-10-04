import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFAD1457);
  static const Color primaryLight = Color(0xFFF8BBD0);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── الخلفية الوردية ──
          Container(
            height: size.height * 0.72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryDark, primary, primary],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── دوائر زخرفية ──
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // ── زر تخطي ──
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'تخطي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ── الصورة (تم تكبير القوس من الأعلى) ──
          Positioned(
            top: size.height * 0.06,     // ✅ الأعلى: رفعناه للأعلى أكثر
            left: 0,
            right: 0,
            height: size.height * 0.68,  // ✅ الارتفاع: زدناه ليصبح أطول
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

          // ── البطاقة السفلية ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.10),
                    blurRadius: 25,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildDot(index == _currentIndex),
                    ),
                  ),
                  const SizedBox(height: 18),

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
                            color: primaryDark,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _pages[_currentIndex]['desc']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentIndex == _pages.length - 1
                          ? double.infinity
                          : 140,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primary, primaryDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentIndex == _pages.length - 1
                                  ? 'ابدأ الآن'
                                  : 'التالي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchPage(Map<String, String> page, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.hasClients &&
            _pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: Transform.scale(
            scale: Curves.easeOutCubic.transform(value),
            child: Container(
              // ✅ تم تكبير القوس: عرض أعرض + ارتفاع أعلى
              width: MediaQuery.of(context).size.width * 0.88,
              height: MediaQuery.of(context).size.height * 0.60, // ✅ ارتفاع أكبر
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 4,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(300), // ✅ نصف قطر أكبر
                  topRight: Radius.circular(300), // ✅ نصف قطر أكبر
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(300),
                  topRight: Radius.circular(300),
                ),
                child: Image.network(
                  page['image']!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: primaryLight.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: primaryLight.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.celebration,
                          size: 80,
                          color: Colors.white,
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
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? primary : Colors.grey.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
