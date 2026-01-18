import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/presentation/screens/auth/auth_choice_screen.dart';
import 'package:frontend/presentation/screens/profile/change_password_screen.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:frontend/core/utils/string_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Hồ sơ",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: _pickAndUploadAvatar,
                            borderRadius: BorderRadius.circular(50),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage: user?.avatar != null
                                  ? NetworkImage(user!.avatar!)
                                  : null,
                              child: user?.avatar == null
                                  ? Text(
                                      user?.fullName?[0].toUpperCase() ?? "U",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (authState.isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? "Người dùng",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildBalanceSection(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildGroupTitle("Tài khoản"),
              _buildSettingsGroup([
                _buildSettingsItem(
                  icon: Icons.person_outline_rounded,
                  title: "Thông tin cá nhân",
                  onTap: () => _showEditProfileDialog(context, user?.fullName),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.lock_outline_rounded,
                  title: "Đổi mật khẩu",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildGroupTitle("Ứng dụng"),
              _buildSettingsGroup([
                _buildSettingsItem(
                  icon: Icons.notifications_none_rounded,
                  title: "Thông báo",
                  onTap: () {},
                ),
                _buildDivider(),
                _buildSettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: "Hướng dẫn & Hỗ trợ",
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AuthChoiceScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Đăng xuất",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Colors.grey[100],
    );
  }

  void _showEditProfileDialog(BuildContext context, String? currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cập nhật thông tin"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Họ và tên",
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .updateProfile(fullName: newName);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Cập nhật thành công"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    try {
      final cloudinaryService = ref.read(cloudinaryServiceProvider);

      final imageUrl = await cloudinaryService.uploadFile(File(image.path));

      if (imageUrl != null) {
        final success = await ref
            .read(authControllerProvider.notifier)
            .updateProfile(avatar: imageUrl);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật ảnh đại diện thành công"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildBalanceSection() {
    final transactionState = ref.watch(transactionControllerProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.05),
            Colors.blueAccent.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 16,
                color: Colors.blueAccent.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "TỔNG SỐ DƯ",
                style: TextStyle(
                  color: Colors.blueAccent.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transactionState.monthlyBalance.toVnd(),
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
