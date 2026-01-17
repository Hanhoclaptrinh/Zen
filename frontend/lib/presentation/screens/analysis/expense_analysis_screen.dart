import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:intl/intl.dart';

enum AnalysisTimeRange { week, month, year }

class ExpenseAnalysisScreen extends ConsumerStatefulWidget {
  const ExpenseAnalysisScreen({super.key});

  @override
  ConsumerState<ExpenseAnalysisScreen> createState() =>
      _ExpenseAnalysisScreenState();
}

class _ExpenseAnalysisScreenState extends ConsumerState<ExpenseAnalysisScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _touchedIndex = -1;
  int _barTouchedIndex = -1;
  AnalysisTimeRange _timeRange = AnalysisTimeRange.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(categoryControllerProvider).categories.isEmpty) {
        ref.read(categoryControllerProvider.notifier).fetchCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionControllerProvider);
    final categoryState = ref.watch(categoryControllerProvider);

    final allTransactions = transactionState.allTransactions;
    final allCategories = categoryState.categories;

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_timeRange) {
      case AnalysisTimeRange.week:
        startDate = now.subtract(const Duration(days: 6));
        break;
      case AnalysisTimeRange.month:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case AnalysisTimeRange.year:
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    final periodTransactions = allTransactions.where((t) {
      return t.type == 'expense' &&
          t.transactionDate.isAfter(
            startDate.subtract(const Duration(seconds: 1)),
          ) &&
          t.transactionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalExpense = periodTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    void addBarGroup(int x, double y) {
      if (y > maxY) maxY = y;
      barGroups.add(
        BarChartGroupData(
          x: x,
          barRods: [
            BarChartRodData(
              toY: y,
              color: _barTouchedIndex == x
                  ? AppColors.accent
                  : AppColors.accent.withOpacity(0.3),
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY == 0 ? 100 : maxY * 1.1,
                color: Colors.grey.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }

    if (_timeRange == AnalysisTimeRange.year) {
      for (int i = 1; i <= 12; i++) {
        final val = periodTransactions
            .where((t) => t.transactionDate.month == i)
            .fold(0.0, (sum, t) => sum + t.amount);
        addBarGroup(i, val);
      }
    } else {
      final daysCount = _timeRange == AnalysisTimeRange.month ? endDate.day : 7;

      if (_timeRange == AnalysisTimeRange.week) {
        for (int i = 0; i < 7; i++) {
          final date = startDate.add(Duration(days: i));
          final val = periodTransactions
              .where(
                (t) =>
                    t.transactionDate.year == date.year &&
                    t.transactionDate.month == date.month &&
                    t.transactionDate.day == date.day,
              )
              .fold(0.0, (sum, t) => sum + t.amount);
          addBarGroup(i, val);
        }
      } else {
        for (int i = 1; i <= daysCount; i++) {
          final val = periodTransactions
              .where((t) => t.transactionDate.day == i)
              .fold(0.0, (sum, t) => sum + t.amount);
          addBarGroup(i, val);
        }
      }
    }

    final Map<int, double> catTotals = {};
    for (var t in periodTransactions) {
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    }
    final List<_CategoryData> categoryDataList = [];
    catTotals.forEach((id, amount) {
      final cat = allCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => CategoryModel(
          id: -1,
          name: 'Khác',
          type: CategoryType.expense,
          icon: Icons.help,
          color: Colors.grey,
        ),
      );
      categoryDataList.add(
        _CategoryData(
          cat,
          amount,
          totalExpense > 0 ? (amount / totalExpense) * 100 : 0,
        ),
      );
    });
    categoryDataList.sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text(
          "Phân tích chi tiêu",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTimeFilter("7 Ngày", AnalysisTimeRange.week),
                    _buildTimeFilter("Tháng này", AnalysisTimeRange.month),
                    _buildTimeFilter("Năm nay", AnalysisTimeRange.year),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Tổng chi tiêu",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(totalExpense),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.textPrimary,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            NumberFormat.compact(locale: 'vi').format(rod.toY),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              barTouchResponse == null ||
                              barTouchResponse.spot == null) {
                            _barTouchedIndex = -1;
                            return;
                          }
                          _barTouchedIndex =
                              barTouchResponse.spot!.touchedBarGroupIndex;
                        });
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            String text = '';

                            if (_timeRange == AnalysisTimeRange.week) {
                              if (index >= 0 && index < 7) {
                                final date = startDate.add(
                                  Duration(days: index),
                                );
                                text = DateFormat('E', 'vi').format(date);
                              }
                            } else if (_timeRange == AnalysisTimeRange.year) {
                              text = 'T$index';
                            } else {
                              if (index % 5 == 0 || index == 1) text = '$index';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Danh mục chi tiêu",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              if (categoryDataList.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Chưa có dữ liệu",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 60,
                              startDegreeOffset: -90,
                              sections: categoryDataList.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final data = entry.value;
                                final isTouched = index == _touchedIndex;
                                final radius = isTouched ? 30.0 : 25.0;

                                return PieChartSectionData(
                                  color: data.category.color,
                                  value: data.amount,
                                  title: '',
                                  radius: radius,
                                  badgeWidget: isTouched
                                      ? _buildBadge(data.category.icon)
                                      : null,
                                  badgePositionPercentageOffset: 1.3,
                                );
                              }).toList(),
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _touchedIndex != -1 &&
                                        _touchedIndex < categoryDataList.length
                                    ? "${categoryDataList[_touchedIndex].percentage.toStringAsFixed(1)}%"
                                    : "Tổng",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _touchedIndex != -1 &&
                                        _touchedIndex < categoryDataList.length
                                    ? categoryDataList[_touchedIndex]
                                          .category
                                          .name
                                    : "Tất cả",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...categoryDataList
                        .map((data) => _buildCategoryItem(data))
                        .toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter(String text, AnalysisTimeRange range) {
    final isSelected = _timeRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timeRange = range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(icon, size: 16),
    );
  }

  Widget _buildCategoryItem(_CategoryData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.category.icon,
              color: data.category.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(data.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: data.percentage / 100,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: data.category.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final CategoryModel category;
  final double amount;
  final double percentage;
  _CategoryData(this.category, this.amount, this.percentage);
}
