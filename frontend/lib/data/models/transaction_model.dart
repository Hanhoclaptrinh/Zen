class TransactionModel {
  final int id;
  final double amount;
  final String? note;
  final String type; // income or expense
  final DateTime transactionDate;
  final int categoryId;

  TransactionModel({
    required this.id,
    required this.amount,
    this.note,
    required this.type,
    required this.transactionDate,
    required this.categoryId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      amount: double.parse(json['amount'].toString()),
      note: json['note'] as String?,
      type: json['type'] as String,
      transactionDate: DateTime.parse(
        json['transactionDate'] as String,
      ).toLocal(),
      categoryId: json['categoryId'] as int,
    );
  }
}
