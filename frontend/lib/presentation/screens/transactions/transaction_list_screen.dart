import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/string_utils.dart';
import 'package:frontend/data/models/transaction_model.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:intl/intl.dart';

class DateGroup {
  final DateTime date;
  final List<TransactionModel> transactions;
  final double totalAmount;

  DateGroup(this.date, this.transactions, this.totalAmount);
}

class TransactionListScreen extends ConsumerWidget {
  final String transactionType; // 'income' or 'expense'

  const TransactionListScreen({super.key, required this.transactionType});

  List<DateGroup> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in transactions) {
      final dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(transaction.transactionDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    // chuyen sang list va sort theo ngay moi nhat
    final List<DateGroup> result = grouped.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final list = entry.value;
      final total = list.fold(0.0, (sum, item) => sum + item.amount);
      return DateGroup(date, list, total);
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return "Hôm nay";
    if (checkDate == yesterday) return "Hôm qua";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionControllerProvider);
    final isIncome = transactionType == 'income';

    final primaryColor = isIncome
        ? const Color(0xFF00B894)
        : const Color(0xFFFF7675);
    final backgroundColor = isIncome
        ? const Color(0xFFE0F9F4)
        : const Color(0xFFFFECEC);
    final title = isIncome ? "Thu nhập" : "Chi tiêu";

    // raw transactions
    final List<TransactionModel> rawTransactions =
        transactionState.allTransactions
            .where((t) => t.type == transactionType)
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    /// total
    final totalListAmount = rawTransactions.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    // grouped by date
    final groupedData = _groupTransactionsByDate(rawTransactions);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(totalListAmount, primaryColor, isIncome),

          Expanded(
            child: rawTransactions.isEmpty
                ? _buildEmptyState(isIncome)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: groupedData.length,
                    itemBuilder: (context, index) {
                      final group = groupedData[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getDateHeader(group.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "${isIncome ? '+' : '-'}${group.totalAmount.toVnd()}",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  offset: const Offset(0, 4),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: group.transactions.length,
                              separatorBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(left: 66),
                                child: Divider(
                                  color: Colors.grey[100],
                                  height: 1,
                                ),
                              ),
                              itemBuilder: (context, i) {
                                final transaction = group.transactions[i];
                                return _buildTransactionItem(
                                  transaction,
                                  primaryColor,
                                  backgroundColor,
                                  isIncome,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double total, Color color, bool isIncome) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIncome
              ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
              : [const Color(0xFFFF7675), const Color(0xFFD63031)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Tổng ${isIncome ? 'thu nhập' : 'chi tiêu'}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total.toVnd(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    TransactionModel transaction,
    Color color,
    Color bgColor,
    bool isIncome,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(
                child: SvgPicture.asset(
                  isIncome ? "assets/adlico.svg" : "assets/aurico.svg",
                  color: color,
                  width: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note ?? (isIncome ? "Thu nhập" : "Chi tiêu"),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2D3436),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(transaction.transactionDate),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              "${isIncome ? '+' : '-'}${transaction.amount.toVnd()}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isIncome
                    ? const Color(0xFF00B894)
                    : const Color(0xFFFF7675),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isIncome) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isIncome
                  ? Icons.account_balance_wallet_rounded
                  : Icons.credit_card_off_rounded,
              size: 60,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Chưa có giao dịch nào",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
