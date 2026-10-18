import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // تم استخدام أسماء الصور التي قمت برفعها في مجلد assets/icons
  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/icons/pexels-amar-14716282.jpg',
      'title': 'مرحباً بك في تطبيق فرح',
      'description': 'أكبر دليل لحجز قاعات الأفراح في ليبيا - تصفح القاعات، قارن الأسعار واحجز بكل سهولة',
    },
    {
      'image': 'assets/icons/pexels-highervibration-10319485.jpg',
      'title': 'ابحث وقارن',
      'description': 'تصفح أفضل القاعات في ليبيا واختر الأنسب لمناسبتك',
    },
    {
      'image': 'assets/icons/pexels-jonathanborba-19894379.jpg',
      'title': 'احجز بثقة',
      'description': 'ادفع رسم حجز بسيط واستمتع بسياسة استرداد مرنة',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // اللون الأساسي للتطبيق (الزهري/الأحمر)
    const Color primaryColor = Color(0xFFD81B60); 

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          // 1. الجزء العلوي: الصورة (تم إعطاؤه مساحة أكبر flex: 6 لإبراز الصورة)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      // الانحناء السفلي للصورة (شكل القوس)
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.elliptical(250, 100),
                        bottomRight: Radius.elliptical(250, 100),
                      ),
                      child: Image.asset( // استخدام Image.asset للصور المحلية
                        _pages[index]['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        // تصميم بديل في حال فشل تحميل الصورة (لتفادي الأيقونة المكسورة)
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.pink.shade100, 
                            child: Center(
                              child: Icon(
                                Icons.image_rounded, 
                                size: 80, 
                                color: Colors.pink.shade300
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                // زر "تخطي" في أعلى اليسار
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: () {
                          // ضع كود الانتقال للشاشة الرئيسية هنا
                          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HallListScreen()));
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
                  ),
                ),
              ],
            ),
          ),

          // 2. الجزء السفلي: الصندوق الأبيض (تم تقليل مساحته إلى flex: 4)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // مؤشرات الصفحات (النقاط)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl, // ضبط الاتجاه للعربية
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8, // النقطة النشطة تصبح مستطيلة
                          decoration: BoxDecoration(
                            color: _currentPage == index ? primaryColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // النصوص (العنوان والوصف)
                    Column(
                      children: [
                        Text(
                          _pages[_currentPage]['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _pages[_currentPage]['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                    // زر التالي
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            // إذا كانت هذه آخر صفحة، انتقل للرئيسية
                            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HallListScreen()));
                          } else {
                            // الانتقال للصفحة التالية
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // السهم متجه لليسار
                            const Icon(
                              Icons.arrow_back_ios, 
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
