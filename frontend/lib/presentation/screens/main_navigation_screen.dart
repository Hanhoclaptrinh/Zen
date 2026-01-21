import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/presentation/screens/analysis/expense_analysis_screen.dart';
import 'package:frontend/presentation/screens/budget/budget_screen.dart';
import 'package:frontend/presentation/screens/camera/camera_ocr_screen.dart';
import 'package:frontend/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/presentation/screens/profile/profile_screen.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'dart:ui';
import 'package:frontend/presentation/screens/transaction/add_transaction_screen.dart';
import 'package:frontend/presentation/screens/camera/camera_capture_screen.dart';
import 'package:frontend/providers/app_providers.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<Widget> _buildScreens() {
    return [
      const DashboardScreen(),
      const ExpenseAnalysisScreen(),
      CameraCaptureScreen(isActive: _selectedIndex == 2),
      const BudgetScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMenuOpen = ref.watch(dashboardMenuControllerProvider);
    final screens = _buildScreens();

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(index: _selectedIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
              if (isMenuOpen) {
                ref.read(dashboardMenuControllerProvider.notifier).close();
              }
            },
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withOpacity(0.1),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            elevation: 10,
            height: 70,
            destinations: [
              NavigationDestination(
                icon: SvgPicture.asset(
                  "assets/homeoutlined.svg",
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  "assets/homefilled.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: SvgPicture.asset(
                  "assets/chartoutlined.svg",
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  "assets/chartfilled.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Phân tích',
              ),
              NavigationDestination(
                icon: SvgPicture.asset(
                  "assets/cameraoutlined.svg",
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  "assets/camerafilled.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Máy ảnh',
              ),
              NavigationDestination(
                icon: SvgPicture.asset(
                  "assets/walletoutlined.svg",
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  "assets/walletfilled.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Hạn mức',
              ),
              NavigationDestination(
                icon: SvgPicture.asset(
                  "assets/useroutlined.svg",
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  "assets/userfilled.svg",
                  colorFilter: const ColorFilter.mode(
                    Colors.blueAccent,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Hồ sơ',
              ),
            ],
          ),
          floatingActionButton: null,
        ),

        // blur background
        if (isMenuOpen && _selectedIndex == 0)
          Positioned.fill(
            child: GestureDetector(
              onTap: () =>
                  ref.read(dashboardMenuControllerProvider.notifier).close(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          ),

        // fab and menu
        if (_selectedIndex == 0)
          Positioned(
            right: 16,
            bottom: 86 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMenuOpen) ...[
                  _buildBubbleMenu(context),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  onPressed: () {
                    ref.read(dashboardMenuControllerProvider.notifier).toggle();
                  },
                  elevation: 0,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBubbleMenu(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBubbleMenuItem(
                  icon: SvgPicture.asset(
                    "assets/noteico.svg",
                    color: Colors.blueAccent,
                  ),
                  label: "Nhập",
                  onTap: () {
                    ref.read(dashboardMenuControllerProvider.notifier).close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTransactionScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildBubbleMenuItem(
                  icon: SvgPicture.asset(
                    "assets/camerafilled.svg",
                    color: Colors.blueAccent,
                  ),
                  label: "Quét bill",
                  onTap: () {
                    ref.read(dashboardMenuControllerProvider.notifier).close();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraOCRScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: CustomPaint(
              size: const Size(20, 12),
              painter: _BubbleTailPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleMenuItem({
    required SvgPicture icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
