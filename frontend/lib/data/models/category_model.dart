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
  static const Map<String, IconData> _iconMapping = {
    'ăn': Icons.restaurant_menu,
    'uống': Icons.local_cafe,
    'lương': Icons.payments_rounded,
    'thưởng': Icons.card_giftcard,
    'xe': Icons.directions_car,
    'nhà': Icons.home_work,
    'điện': Icons.electric_bolt,
    'nước': Icons.water_drop,
    'học': Icons.school,
    'y tế': Icons.health_and_safety,
    'mua': Icons.shopping_cart,
    'net': Icons.wifi,
    'giải trí': Icons.theater_comedy,
    'du lịch': Icons.flight_takeoff,
  };

  static const Map<String, Color> _colorMapping = {
    'ăn': Colors.orange,
    'uống': Colors.brown,
    'xe': Colors.blue,
    'nhà': Colors.purple,
    'sắm': Colors.pink,
    'lương': Colors.green,
    'thưởng': Colors.redAccent,
    'y tế': Colors.red,
    'học': Colors.indigo,
    'điện': Colors.amber,
    'nước': Colors.lightBlue,
  };

  IconData get icon {
    final lowerName = name.toLowerCase();
    for (var entry in _iconMapping.entries) {
      if (lowerName.contains(entry.key)) return entry.value;
    }
    return Icons.help_outline;
  }

  Color get color {
    final lowerName = name.toLowerCase();
    for (var entry in _colorMapping.entries) {
      if (lowerName.contains(entry.key)) return entry.value;
    }
    return Colors.grey;
  }
}
