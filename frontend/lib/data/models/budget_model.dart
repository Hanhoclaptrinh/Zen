import 'package:frontend/data/models/category_model.dart';

class BudgetModel {
  final int id;
  final double amountLimit;
  final String period; // monthly, weekly
  final int userId;
  final int? categoryId;
  final DateTime createdAt;
  final CategoryModel? category;

  BudgetModel({
    required this.id,
    required this.amountLimit,
    required this.period,
    required this.userId,
    this.categoryId,
    required this.createdAt,
    this.category,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as int,
      amountLimit: double.parse(json['amountLimit'].toString()),
      period: json['period'] as String,
      userId: json['userId'] as int,
      categoryId: json['categoryId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
    );
  }
}
