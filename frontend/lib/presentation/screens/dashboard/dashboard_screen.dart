import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/utils/string_utils.dart';
import 'package:intl/intl.dart';
import 'package:frontend/presentation/screens/auth/auth_choice_screen.dart';
import 'package:frontend/presentation/screens/transaction/add_transaction_screen.dart';
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
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawerEnableOpenDragGesture: true,
      drawer: _buildDrawer(context, ref),
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset("assets/menuico.svg"),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
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
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
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
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Xin chào, ${authState.user?.fullName ?? 'User'}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            transactionState.filterMode == FilterMode.day
                                ? DateFormat('dd MMM, yyyy', 'vi_VN')
                                      .format(transactionState.selectedDate)
                                      .capitalize()
                                : DateFormat('MMMM, yyyy', 'vi_VN')
                                      .format(transactionState.selectedDate)
                                      .capitalize(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF130F40), Color(0xFF000000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Số dư hiện tại",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${transactionState.balance.toVnd()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
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
                          color: const Color(0xFF00B894),
                          icon: SvgPicture.asset(
                            "assets/adlico.svg",
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: "Chi",
                          amount: transactionState.totalExpense,
                          color: const Color(0xFFFF7675),
                          icon: SvgPicture.asset(
                            "assets/aurico.svg",
                            color: Colors.redAccent,
                          ),
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
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${transactionState.filteredTransactions.length} giao dịch",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recent Transactions Panel
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
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                transaction.type == 'income'
                                                ? const Color(
                                                    0xFF00B894,
                                                  ).withOpacity(0.1)
                                                : const Color(
                                                    0xFFFF7675,
                                                  ).withOpacity(0.1),
                                            child: transaction.type == 'income'
                                                ? SvgPicture.asset(
                                                    "assets/adlico.svg",
                                                    color: Colors.greenAccent,
                                                  )
                                                : SvgPicture.asset(
                                                    "assets/aurico.svg",
                                                    color: Colors.redAccent,
                                                  ),
                                          ),
                                          title: Text(
                                            transaction.note ?? "Giao dịch",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            DateFormat('dd/MM HH:mm').format(
                                              transaction.transactionDate,
                                            ),
                                          ),
                                          trailing: Text(
                                            "${transaction.type == 'income' ? '+' : '-'}${transaction.amount.toVnd()}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  transaction.type == 'income'
                                                  ? const Color(0xFF00B894)
                                                  : const Color(0xFFFF7675),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF0057FF),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF130F40)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF130F40)),
                ),
                const SizedBox(height: 12),
                Text(
                  "Xin chào, ${authState.user?.fullName ?? 'Alex'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${authState.user?.email ?? 'user@gmail.com'}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
                color: Colors.black,
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

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
