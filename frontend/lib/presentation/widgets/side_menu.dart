import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/presentation/screens/analysis/expense_analysis_screen.dart';
import 'package:frontend/presentation/screens/auth/auth_choice_screen.dart';
import 'package:frontend/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/providers/app_providers.dart';

class SideMenu extends ConsumerWidget {
  final String currentRoute;

  const SideMenu({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.7,
      child: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF130F40), Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(topRight: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authState.user?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authState.user?.email ?? 'user@gmail.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildModernDrawerItem(
                    context,
                    ref,
                    icon: "assets/homeico.svg",
                    title: 'Trang chủ',
                    isSelected: currentRoute == 'home',
                    onTap: () {
                      if (currentRoute == 'home') {
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const DashboardScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                  _buildModernDrawerItem(
                    context,
                    ref,
                    icon: "assets/chartico.svg",
                    title: 'Phân tích',
                    isSelected: currentRoute == 'analysis',
                    onTap: () {
                      if (currentRoute == 'analysis') {
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const ExpenseAnalysisScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      }
                    },
                  ),
                  _buildModernDrawerItem(
                    context,
                    ref,
                    icon: "assets/userico.svg",
                    title: 'Hồ sơ',
                    isSelected: currentRoute == 'profile',
                    onTap: () {
                      Navigator.pop(context);
                      // navigate to profile screen
                    },
                  ),
                  const Divider(height: 40, thickness: 1),
                  _buildModernDrawerItem(
                    context,
                    ref,
                    icon: null,
                    isLogout: true,
                    title: 'Đăng xuất',
                    isSelected: false,
                    onTap: () {
                      ref.read(authControllerProvider.notifier).logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthChoiceScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Zen - 2026",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawerItem(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    String? icon,
    required bool isSelected,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    final color = isLogout
        ? Colors.redAccent
        : (isSelected ? const Color(0xFF0057FF) : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0057FF).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (icon != null)
                SvgPicture.asset(
                  icon,
                  width: 22,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else if (isLogout)
                SvgPicture.asset("assets/logoutico.svg"),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: isSelected || isLogout
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
