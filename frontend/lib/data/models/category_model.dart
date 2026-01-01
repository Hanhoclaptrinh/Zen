import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final int id;
  final String name;
  final CategoryType type;

  CategoryModel({required this.id, required this.name, required this.type});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
    );
  }

  // icon helper
  IconData get icon {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ăn') || lowerName.contains('food'))
      return Icons.restaurant;
    if (lowerName.contains('uống') || lowerName.contains('drink'))
      return Icons.local_cafe;
    if (lowerName.contains('đi') || lowerName.contains('transport'))
      return Icons.directions_car;
    if (lowerName.contains('nhà') || lowerName.contains('home'))
      return Icons.home;
    if (lowerName.contains('sắm') || lowerName.contains('shop'))
      return Icons.shopping_bag;
    if (lowerName.contains('lương') || lowerName.contains('salary'))
      return Icons.attach_money;
    if (lowerName.contains('thưởng') || lowerName.contains('bonus'))
      return Icons.card_giftcard;
    if (lowerName.contains('y tế') || lowerName.contains('health'))
      return Icons.local_hospital;
    if (lowerName.contains('học') || lowerName.contains('education'))
      return Icons.school;
    return Icons.category; // default icon
  }

  Color get color {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ăn')) return Colors.orange;
    if (lowerName.contains('uống')) return Colors.brown;
    if (lowerName.contains('đi')) return Colors.blue;
    if (lowerName.contains('nhà')) return Colors.purple;
    if (lowerName.contains('sắm')) return Colors.pink;
    if (lowerName.contains('lương')) return Colors.green;
    if (lowerName.contains('y tế')) return Colors.red;
    return Colors.grey;
  }
}
