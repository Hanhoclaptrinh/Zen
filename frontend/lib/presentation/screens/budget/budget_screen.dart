import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/data/models/budget_model.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:frontend/presentation/widgets/side_menu.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetControllerProvider.notifier).fetchBudgets();
      if (ref.read(categoryControllerProvider).categories.isEmpty) {
        ref.read(categoryControllerProvider.notifier).fetchCategories();
      }
    });
  }

  void _showAddBudgetDialog([BudgetModel? budget]) {
    final isEditing = budget != null;
    double amount = budget?.amountLimit ?? 0;
    int? categoryId = budget?.categoryId;
    String period = budget?.period ?? 'monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? "Chỉnh sửa hạn mức" : "Thêm hạn mức mới",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Số tiền hạn mức",
                  prefixText: "đ ",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: TextEditingController(
                  text: isEditing ? amount.toString() : "",
                ),
                onChanged: (val) => amount = double.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 16),
              const Text(
                "Kỳ hạn",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPeriodChip(
                    "Hàng tháng",
                    'monthly',
                    period,
                    (p) => setModalState(() => period = p),
                  ),
                  const SizedBox(width: 12),
                  _buildPeriodChip(
                    "Hàng tuần",
                    'weekly',
                    period,
                    (p) => setModalState(() => period = p),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Danh mục (Tùy chọn)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final cats = ref
                      .watch(categoryControllerProvider)
                      .categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: categoryId,
                        isExpanded: true,
                        hint: const Text("Tất cả danh mục"),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("Tất cả danh mục"),
                          ),
                          ...cats.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => categoryId = val),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amount <= 0) return;
                    final data = {
                      'amountLimit': amount,
                      'period': period,
                      'categoryId': categoryId,
                    };
                    bool success;
                    if (isEditing) {
                      success = await ref
                          .read(budgetControllerProvider.notifier)
                          .updateBudget(budget.id, data);
                    } else {
                      success = await ref
                          .read(budgetControllerProvider.notifier)
                          .addBudget(data);
                    }
                    if (success) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(isEditing ? "Cập nhật" : "Lưu hạn mức"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetControllerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawerEnableOpenDragGesture: true,
      drawer: const SideMenu(currentRoute: 'budget'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.asset("assets/menuico.svg"),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          "Hạn mức chi tiêu",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          child: budgetState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : budgetState.budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Chưa có hạn mức nào",
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddBudgetDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Thiết lập ngay"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: budgetState.budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgetState.budgets[index];
                    return _buildBudgetCard(budget);
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: budget.category != null
                          ? budget.category!.color.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      budget.category?.icon ?? Icons.all_inclusive,
                      color: budget.category?.color ?? AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category?.name ?? "Tổng chi tiêu",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        budget.period == 'monthly' ? "Hàng tháng" : "Hàng tuần",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Actions (Edit/Delete)
                  _showActions(budget);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Hạn mức", style: TextStyle(color: Colors.grey)),
              Text(
                NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                ).format(budget.amountLimit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActions(BudgetModel budget) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Chỉnh sửa"),
            onTap: () {
              Navigator.pop(context);
              _showAddBudgetDialog(budget);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Xóa", style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(budgetControllerProvider.notifier)
                  .deleteBudget(budget.id);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
