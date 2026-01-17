import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/presentation/screens/analysis/expense_analysis_screen.dart';
import 'package:frontend/presentation/screens/budget/budget_screen.dart';
import 'package:frontend/presentation/screens/camera/camera_ocr_screen.dart';
import 'package:frontend/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/presentation/screens/profile/profile_screen.dart';
import 'package:frontend/core/constants/app_colors.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpenseAnalysisScreen(),
    const CameraOCRScreen(),
    const BudgetScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 10,
        height: 70,
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset("assets/homeoutlined.svg"),
            selectedIcon: SvgPicture.asset(
              "assets/homefilled.svg",
              color: Colors.blueAccent,
            ),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: SvgPicture.asset("assets/chartoutlined.svg"),
            selectedIcon: SvgPicture.asset(
              "assets/chartfilled.svg",
              color: Colors.blueAccent,
            ),
            label: 'Phân tích',
          ),
          NavigationDestination(
            icon: SvgPicture.asset("assets/cameraoutlined.svg"),
            selectedIcon: SvgPicture.asset(
              "assets/camerafilled.svg",
              color: Colors.blueAccent,
            ),
            label: 'OCR',
          ),
          NavigationDestination(
            icon: SvgPicture.asset("assets/walletoutlined.svg"),
            selectedIcon: SvgPicture.asset(
              "assets/walletfilled.svg",
              color: Colors.blueAccent,
            ),
            label: 'Hạn mức',
          ),
          NavigationDestination(
            icon: SvgPicture.asset("assets/useroutlined.svg"),
            selectedIcon: SvgPicture.asset(
              "assets/userfilled.svg",
              color: Colors.blueAccent,
            ),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
