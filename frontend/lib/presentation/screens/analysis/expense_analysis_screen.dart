import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:frontend/presentation/widgets/side_menu.dart';
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
  AnalysisTimeRange _timeRange = AnalysisTimeRange.month;

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

    // filter range
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_timeRange) {
      case AnalysisTimeRange.week:
        // week
        startDate = now.subtract(const Duration(days: 7));
        break;
      case AnalysisTimeRange.month:
        // month
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalysisTimeRange.year:
        // year
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    final periodTransactions = allTransactions.where((t) {
      return t.type == 'expense' &&
          t.transactionDate.isAfter(
            startDate.subtract(const Duration(seconds: 1)),
          ) &&
          t.transactionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          ); // inclusiveish
    }).toList();

    // total expense
    final totalExpense = periodTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    // trend spots
    List<FlSpot> trendSpots = [];
    double maxY = 0;

    if (_timeRange == AnalysisTimeRange.year) {
      for (int i = 1; i <= 12; i++) {
        final monthTotal = periodTransactions
            .where((t) => t.transactionDate.month == i)
            .fold(0.0, (sum, t) => sum + t.amount);
        if (monthTotal > maxY) maxY = monthTotal;
        trendSpots.add(FlSpot(i.toDouble(), monthTotal));
      }
    } else {
      // final days = _timeRange == AnalysisTimeRange.week ? 7 : now.day;
      final daysCount = _timeRange == AnalysisTimeRange.month
          ? DateTime(now.year, now.month + 1, 0).day
          : 7;

      for (int i = 1; i <= daysCount; i++) {
        double val = 0;
        if (_timeRange == AnalysisTimeRange.week) {
          final date = startDate.add(Duration(days: i - 1));
          val = periodTransactions
              .where(
                (t) =>
                    t.transactionDate.year == date.year &&
                    t.transactionDate.month == date.month &&
                    t.transactionDate.day == date.day,
              )
              .fold(0.0, (sum, t) => sum + t.amount);
        } else {
          val = periodTransactions
              .where((t) => t.transactionDate.day == i)
              .fold(0.0, (sum, t) => sum + t.amount);
        }
        if (val > maxY) maxY = val;
        trendSpots.add(FlSpot(i.toDouble(), val));
      }
    }

    // pie chart
    final Map<int, double> catTotals = {};
    for (var t in periodTransactions) {
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0) + t.amount;
    }

    // convert IDs to Category Models
    final List<_CategoryData> categoryDataList = [];
    catTotals.forEach((id, amount) {
      final cat = allCategories.firstWhere(
        (c) => c.id == id,
        orElse: () =>
            CategoryModel(id: -1, name: 'Khác', type: CategoryType.expense),
      );
      categoryDataList.add(
        _CategoryData(cat, amount, (amount / totalExpense) * 100),
      );
    });
    // sort by amount desc
    categoryDataList.sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: const SideMenu(currentRoute: 'analysis'), // marker
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.asset("assets/menuico.svg"),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          "Phân tích",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTimeFilterOption("Tuần", AnalysisTimeRange.week),
                  _buildTimeFilterOption("Tháng", AnalysisTimeRange.month),
                  _buildTimeFilterOption("Năm", AnalysisTimeRange.year),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              "Tổng chi tiêu",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
              ).format(totalExpense),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
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
                        reservedSize: 30,
                        interval: _timeRange == AnalysisTimeRange.week ? 1 : 5,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxY * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendSpots,
                      isCurved: true,
                      color: const Color(0xFF0057FF),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF0057FF).withOpacity(0.05),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            NumberFormat.compact(locale: 'vi').format(spot.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chi tiết danh mục",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (categoryDataList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  "Chưa có dữ liệu cho thời gian này",
                  style: TextStyle(color: Colors.grey[400]),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: categoryDataList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final data = entry.value;
                          final isTouched = index == _touchedIndex;
                          final radius = isTouched ? 60.0 : 50.0;
                          return PieChartSectionData(
                            color: data.category.color,
                            value: data.amount,
                            title: '',
                            radius: radius,
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
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
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: categoryDataList.take(5).map((data) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: data.category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data.category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${data.percentage.toStringAsFixed(1)}%",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // list details
            if (categoryDataList.isNotEmpty)
              Column(
                children: categoryDataList.map((data) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: data.category.color.withOpacity(0.1),
                            shape: BoxShape.circle,
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
                              Text(
                                data.category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${data.percentage.toStringAsFixed(1)}% chi tiêu",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterOption(String text, AnalysisTimeRange range) {
    final isSelected = _timeRange == range;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timeRange = range;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
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
