import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class CategoryModel {
  final int id;
  final String name;
  final CategoryType type;

  // luu truc tiep gia tri cua icon va color
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Khác';
    final typeStr = json['type'] as String?;

    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: name,
      type: typeStr == 'income' ? CategoryType.income : CategoryType.expense,
      icon: _getIconByName(name),
      color: _getColorByName(name),
    );
  }

  // helper methods
  static IconData _getIconByName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ăn') || lowerName.contains('thực phẩm'))
      return Icons.restaurant_menu_rounded;
    if (lowerName.contains('uống') || lowerName.contains('cafe'))
      return Icons.local_cafe_rounded;
    if (lowerName.contains('xe') || lowerName.contains('xăng'))
      return Icons.directions_car_rounded;
    if (lowerName.contains('nhà') || lowerName.contains('thuê'))
      return Icons.home_rounded;
    if (lowerName.contains('điện')) return Icons.electric_bolt_rounded;
    if (lowerName.contains('nước')) return Icons.water_drop_rounded;
    if (lowerName.contains('mua') || lowerName.contains('sắm'))
      return Icons.shopping_bag_rounded;
    if (lowerName.contains('y tế') || lowerName.contains('thuốc'))
      return Icons.medical_services_rounded;
    if (lowerName.contains('lương')) return Icons.attach_money_rounded;
    if (lowerName.contains('thưởng')) return Icons.card_giftcard_rounded;
    if (lowerName.contains('giải trí') || lowerName.contains('phim'))
      return Icons.movie_rounded;
    if (lowerName.contains('học') || lowerName.contains('sách'))
      return Icons.school_rounded;
    if (lowerName.contains('quà') || lowerName.contains('tặng'))
      return Icons.card_giftcard_rounded;
    if (lowerName.contains('lợi nhuận')) return Icons.attach_money_rounded;

    return Icons.category_rounded;
  }

  static Color _getColorByName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('ăn')) return const Color(0xFFF59E0B);
    if (lowerName.contains('uống')) return const Color(0xFF78350F);
    if (lowerName.contains('xe')) return const Color(0xFF3B82F6);
    if (lowerName.contains('nhà')) return const Color(0xFF8B5CF6);
    if (lowerName.contains('điện')) return const Color(0xFFEAB308);
    if (lowerName.contains('nước')) return const Color(0xFF0EA5E9);
    if (lowerName.contains('y tế')) return const Color(0xFFEF4444);
    if (lowerName.contains('lương')) return const Color(0xFF10B981);

    return Colors.primaries[name.hashCode % Colors.primaries.length];
  }
}
