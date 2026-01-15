class TransactionModel {
  final int id;
  final double amount;
  final String? note;
  final String type; // income or expense
  final DateTime transactionDate;
  final int categoryId;
  final bool isSplit;
  final List<SplitDetailModel>? splitDetails;

  TransactionModel({
    required this.id,
    required this.amount,
    this.note,
    required this.type,
    required this.transactionDate,
    required this.categoryId,
    this.isSplit = false,
    this.splitDetails,
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
      isSplit: json['isSplit'] as bool? ?? false,
      splitDetails: json['splitDetails'] != null
          ? (json['splitDetails'] as List)
                .map((i) => SplitDetailModel.fromJson(i))
                .toList()
          : null,
    );
  }
}

class SplitDetailModel {
  final int? id;
  final String name;
  final double amount;
  final bool isPaid;

  SplitDetailModel({
    this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
  });

  factory SplitDetailModel.fromJson(Map<String, dynamic> json) {
    return SplitDetailModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: double.parse(json['amount'].toString()),
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'isPaid': isPaid,
  };
}
