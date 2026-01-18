import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/utils/string_utils.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:frontend/presentation/screens/transaction/add_transaction_screen.dart';
import 'package:frontend/presentation/screens/transactions/transaction_list_screen.dart';
import 'package:frontend/providers/app_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionControllerProvider.notifier).fetchTransactions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AnimatedFilterToggle(
              filterMode: transactionState.filterMode,
              onChanged: (mode) {
                ref
                    .read(transactionControllerProvider.notifier)
                    .setFilterMode(mode);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(transactionControllerProvider.notifier)
                .fetchTransactions();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accent.withOpacity(0.1),
                      backgroundImage: authState.user?.avatar != null
                          ? NetworkImage(authState.user!.avatar!)
                          : null,
                      child: authState.user?.avatar == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Xin chào,",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          authState.user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      transactionState.filterMode == FilterMode.day
                          ? DateFormat(
                              'dd/MM',
                            ).format(transactionState.selectedDate)
                          : DateFormat(
                              'MM/yyyy',
                            ).format(transactionState.selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Tổng số dư",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        transactionState.monthlyBalance.toVnd(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: "Thu",
                        amount: transactionState.totalIncome,
                        color: AppColors.success,
                        icon: SvgPicture.asset(
                          "assets/adlico.svg",
                          color: AppColors.success,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TransactionListScreen(
                                transactionType: 'income',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCard(
                        title: "Chi",
                        amount: transactionState.totalExpense,
                        color: AppColors.danger,
                        icon: SvgPicture.asset(
                          "assets/aurico.svg",
                          color: AppColors.danger,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TransactionListScreen(
                                transactionType: 'expense',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transactionState.filterMode == FilterMode.day
                          ? "Giao dịch hôm nay"
                          : "Giao dịch tháng này",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "${transactionState.filteredTransactions.length} giao dịch",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (transactionState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: transactionState.filteredTransactions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text("Chưa có giao dịch nào"),
                            ),
                          )
                        : Column(
                            children: transactionState.filteredTransactions
                                .take(5)
                                .map((transaction) {
                                  return Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddTransactionScreen(
                                                    transaction: transaction,
                                                  ),
                                            ),
                                          );
                                        },
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              transaction.type == 'income'
                                              ? AppColors.success.withOpacity(
                                                  0.1,
                                                )
                                              : AppColors.danger.withOpacity(
                                                  0.1,
                                                ),
                                          child: transaction.type == 'income'
                                              ? SvgPicture.asset(
                                                  "assets/adlico.svg",
                                                  color: AppColors.success,
                                                )
                                              : SvgPicture.asset(
                                                  "assets/aurico.svg",
                                                  color: AppColors.danger,
                                                ),
                                        ),
                                        title: Text(
                                          transaction.note ?? "Giao dịch",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat(
                                            'dd/MM HH:mm',
                                          ).format(transaction.transactionDate),
                                        ),
                                        trailing: Text(
                                          "${transaction.type == 'income' ? '+' : '-'}${transaction.amount.toVnd()}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: transaction.type == 'income'
                                                ? AppColors.success
                                                : AppColors.danger,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (transaction !=
                                          transactionState
                                              .filteredTransactions
                                              .last)
                                        Divider(
                                          color: Colors.grey.shade100,
                                          height: 1,
                                        ),
                                    ],
                                  );
                                })
                                .toList(),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFilterToggle extends StatelessWidget {
  final FilterMode filterMode;
  final ValueChanged<FilterMode> onChanged;

  const _AnimatedFilterToggle({
    required this.filterMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const double width = 140;
    const double height = 36;
    const double padding = 4;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: filterMode == FilterMode.day
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              width: (width / 2) - padding,
              height: height - (padding * 2),
              margin: const EdgeInsets.symmetric(horizontal: padding),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Row(
            children: [
              _buildOption(context, "Ngày", FilterMode.day),
              _buildOption(context, "Tháng", FilterMode.month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, FilterMode mode) {
    final isSelected = filterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final SvgPicture icon;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 16, height: 16, child: icon),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}",
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
