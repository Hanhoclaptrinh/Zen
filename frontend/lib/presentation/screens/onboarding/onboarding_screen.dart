import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/presentation/screens/auth/auth_choice_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "title": "Làm chủ\nchi tiêu",
      "description":
          "Theo dõi mọi khoản thu chi hàng ngày\nmột cách tự động và thông minh.",
      "icon": "assets/ob1.svg",
    },
    {
      "title": "Tiết kiệm\ntối ưu",
      "description":
          "Thiết lập mục tiêu tài chính và để chúng tôi\ngiúp bạn đạt được chúng nhanh hơn.",
      "icon": "assets/ob2.svg",
    },
    {
      "title": "Bảo mật\ndữ liệu",
      "description":
          "Thông tin tài chính của bạn luôn được\nbảo mật an toàn với công nghệ mã hóa mới nhất.",
      "icon": "assets/ob3.svg",
    },
  ];

  void _onNext() {
    if (_currentIndex < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startAuth();
    }
  }

  void _startAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // background
          Column(
            children: [
              Expanded(
                flex: 3,
                child: ClipPath(
                  clipper: OnboardingHeaderClipper(),
                  child: Container(
                    color: AppColors.secondary,
                    width: double.infinity,
                  ),
                ),
              ),
              Expanded(flex: 2, child: Container(color: Colors.white)),
            ],
          ),

          // page view
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: SafeArea(
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          child: SvgPicture.asset(
                            data['icon'],
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Text(
                            data['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF130F40),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['description'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _startAuth,
                      child: const Text(
                        "Bỏ qua",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        _onboardingData.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFF130F40)
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onNext,
                      child: Text(
                        _currentIndex == _onboardingData.length - 1
                            ? "Bắt đầu"
                            : "Tiếp theo",
                        style: const TextStyle(
                          color: Color(0xFF130F40),
                          fontWeight: FontWeight.w800,
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

class OnboardingHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
