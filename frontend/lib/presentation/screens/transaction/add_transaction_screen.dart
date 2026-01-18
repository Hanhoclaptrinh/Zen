import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/data/models/transaction_model.dart';
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
  final double? initialAmount;
  final String? initialNote;
  final String? initialImageUrl;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialAmount,
    this.initialNote,
    this.initialImageUrl,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late PageController _pageController;
  bool _isIncome = false;
  bool _isSplit = false;
  final List<Map<String, dynamic>> _splitDetails = [];

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  String? _imageUrl;

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
      _isSplit = t.isSplit;
      if (t.splitDetails != null) {
        for (var split in t.splitDetails!) {
          _splitDetails.add({
            'name': split.name,
            'amount': split.amount,
            'isPaid': split.isPaid,
          });
        }
      }
    } else {
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '',
        ).format(widget.initialAmount).trim();
      }
      if (widget.initialNote != null) {
        _noteController.text = widget.initialNote!;
      }
      if (widget.initialImageUrl != null) {
        _imageUrl = widget.initialImageUrl;
      }
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

  void _addSplitPerson() {
    setState(() {
      _splitDetails.add({'name': '', 'amount': 0.0, 'isPaid': false});
    });
  }

  void _removeSplitPerson(int index) {
    setState(() {
      _splitDetails.removeAt(index);
    });
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
              primary: AppColors.primary,
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

    final double totalAmount = double.parse(amountText);

    if (_isSplit) {
      double splitSum = 0;
      for (var split in _splitDetails) {
        if (split['name'].toString().isEmpty) {
          _showError('Vui lòng nhập tên người chia');
          return;
        }
        splitSum += double.parse(split['amount'].toString());
      }
      if (splitSum > totalAmount) {
        _showError('Tổng tiền chia vượt quá số tiền chi tiêu');
        return;
      }
    }

    final data = {
      'amount': totalAmount,
      'note': _noteController.text,
      'type': _selectedCategory!.type == CategoryType.income
          ? 'income'
          : 'expense',
      'categoryId': _selectedCategory!.id,
      'transactionDate': _selectedDate.toIso8601String(),
      'isSplit': _isSplit,
      'splitDetails': _isSplit ? _splitDetails : null,
      'imageUrl': _imageUrl,
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
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRadioOption(
                          "Thu nhập",
                          'income',
                          selectedType,
                          (val) => setState(() => selectedType = val),
                          AppColors.accent,
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
                    style: TextStyle(color: AppColors.textSecondary),
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
                    backgroundColor: AppColors.primary,
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
            color: isSelected ? color : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.blueAccent, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.transaction != null
            ? const Text(
                "Sửa chi tiêu",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              )
            : _buildToggleSwitch(),
        actions: [
          IconButton(
            onPressed: () => _showAddCategoryDialog(context),
            icon: SvgPicture.asset("assets/addico.svg", color: Colors.blueAccent,),
            tooltip: "Thêm danh mục",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (_imageUrl != null) _buildImagePreview(),
            _buildAmountInput(),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(36),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildNoteInput()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_isIncome) ...[
                    _buildSplitToggle(),
                    if (_isSplit) _buildSplitDetailsList(),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    "Danh mục",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: categoryState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _isIncome = index == 1;
                                _selectedCategory = null;
                                if (_isIncome) _isSplit = false;
                              });
                            },
                            children: [
                              _buildCategoryPage(expenseCategories),
                              _buildCategoryPage(incomeCategories),
                            ],
                          ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: Colors.blueAccent.withOpacity(0.4),
            ),
            child: Text(
              widget.transaction != null ? "Lưu thay đổi" : "Lưu chi tiêu",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset("assets/teamico.svg", width: 30, height: 30),
              const SizedBox(width: 12),
              const Text(
                "Chia tiền cho nhiều người",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Switch(
            value: _isSplit,
            onChanged: (val) => setState(() => _isSplit = val),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSplitDetailsList() {
    return Column(
      children: [
        ..._splitDetails.asMap().entries.map((entry) {
          int idx = entry.key;
          var detail = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (val) => _splitDetails[idx]['name'] = val,
                    decoration: InputDecoration(
                      hintText: "Tên người",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    controller: TextEditingController(text: detail['name']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (val) => _splitDetails[idx]['amount'] =
                        double.tryParse(val) ?? 0.0,
                    decoration: InputDecoration(
                      hintText: "Số tiền",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(
                      text: detail['amount'] == 0.0
                          ? ''
                          : detail['amount'].toString(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: () => _removeSplitPerson(idx),
                ),
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: _addSplitPerson,
          icon: const Icon(Icons.add, size: 20),
          label: const Text("Thêm người"),
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem("Chi tiêu", false),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        IntrinsicWidth(
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(color: Colors.grey[300]),
              suffixText: "đ",
              suffixStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SvgPicture.asset("assets/cldico.svg"),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Ghi chú...",
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          icon: SvgPicture.asset("assets/noteico.svg"),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildCategoryPage(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có danh mục.\nNhấn dấu + để thêm.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
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
                  color: isSelected ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              _imageUrl!,
              width: 120,
              height: 180,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _imageUrl = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
