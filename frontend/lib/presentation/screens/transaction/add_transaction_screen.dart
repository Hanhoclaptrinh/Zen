import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/data/models/transaction_model.dart'; // Import
import 'package:frontend/providers/app_providers.dart';
import 'package:intl/intl.dart';

// currency formatter
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction; // neu truyen vao data cu -> edit mode

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late PageController _pageController;
  bool _isIncome = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // init logic for edit mode
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _isIncome = t.type == 'income';
      _amountController.text = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '',
      ).format(t.amount).trim();
      _noteController.text = t.note ?? '';
      _selectedDate = t.transactionDate;
      // category will be set after fetching categories
    }

    _pageController = PageController(initialPage: _isIncome ? 1 : 0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryControllerProvider.notifier).fetchCategories();

      if (widget.transaction != null && mounted) {
        final categories = ref.read(categoryControllerProvider).categories;
        try {
          final match = categories.firstWhere(
            (c) => c.id == widget.transaction!.categoryId,
          );
          setState(() {
            _selectedCategory = match;
          });
        } catch (_) {
          // category might be deleted
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // chon ngay
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0057FF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // luu giao dich
  void _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (amountText.isEmpty) {
      _showError('Vui lòng nhập số tiền');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Vui lòng chọn danh mục');
      return;
    }

    final double amount = double.parse(amountText);

    final data = {
      'amount': amount,
      'note': _noteController.text,
      'type': _selectedCategory!.type == CategoryType.income
          ? 'income'
          : 'expense',
      'categoryId': _selectedCategory!.id,
      'transactionDate': _selectedDate.toIso8601String(),
    };

    bool success;
    if (widget.transaction != null) {
      // update
      success = await ref
          .read(transactionControllerProvider.notifier)
          .updateTransaction(widget.transaction!.id, data);
    } else {
      // create
      success = await ref
          .read(transactionControllerProvider.notifier)
          .addTransaction(data);
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      _showError('Có lỗi xảy ra, vui lòng thử lại');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // them cate moi
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = _isIncome ? 'income' : 'expense';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Thêm danh mục mới",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Tên danh mục",
                      hintText: "Ví dụ: Lương, Ăn uống...",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRadioOption(
                          "Chi tiêu",
                          'expense',
                          selectedType,
                          (val) => setState(() => selectedType = val),
                          const Color(0xFFFF7675),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRadioOption(
                          "Thu nhập",
                          'income',
                          selectedType,
                          (val) => setState(() => selectedType = val),
                          const Color(0xFF00B894),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Hủy",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final success = await ref
                        .read(categoryControllerProvider.notifier)
                        .addCategory(nameController.text.trim(), selectedType);
                    if (success && mounted) {
                      Navigator.pop(context);
                      if ((selectedType == 'income') != _isIncome) {
                        _pageController.animateToPage(
                          selectedType == 'income' ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0057FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Thêm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged,
    Color color,
  ) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryControllerProvider);

    final expenseCategories = categoryState.categories
        .where((c) => c.type == CategoryType.expense)
        .toList();
    final incomeCategories = categoryState.categories
        .where((c) => c.type == CategoryType.income)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.transaction != null
            ? const Text(
                "Chỉnh sửa giao dịch",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )
            : _buildToggleSwitch(),
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            tooltip: "Thêm danh mục",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildAmountInput(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(child: _buildDatePicker()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNoteInput()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Danh mục",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: categoryState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _isIncome = index == 1;
                                _selectedCategory = null;
                              });
                            },
                            children: [
                              _buildCategoryPage(expenseCategories),
                              _buildCategoryPage(incomeCategories),
                            ],
                          ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isIncome
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFF7675),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor:
                  (_isIncome
                          ? const Color(0xFF00B894)
                          : const Color(0xFFFF7675))
                      .withOpacity(0.4),
            ),
            child: Text(
              widget.transaction != null ? "Lưu thay đổi" : "Lưu giao dịch",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem("Chi tiêu", false),
          const SizedBox(width: 4),
          _buildToggleItem("Thu nhập", true),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String text, bool isIncomeTab) {
    final isSelected = _isIncome == isIncomeTab;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          isIncomeTab ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isIncomeTab
                    ? const Color(0xFF00B894)
                    : const Color(0xFFFF7675))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      children: [
        const Text(
          "Số tiền",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        IntrinsicWidth(
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: _isIncome
                  ? const Color(0xFF00B894)
                  : const Color(0xFFFF7675),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(color: Colors.grey[300]),
              suffixText: "đ",
              suffixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  // Shared Date Picker
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset("assets/cldico.svg"),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Ghi chú...",
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          icon: SvgPicture.asset("assets/noteico.svg"),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildCategoryPage(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          "Chưa có danh mục.\nNhấn dấu + để thêm.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory?.id == category.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? category.color : Colors.grey[50],
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: category.color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[200]!,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: isSelected ? Colors.white : category.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
