import 'package:flutter/material.dart';

import '../models/category.dart';

/// Label kecil berwarna untuk kategori tugas.
class CategoryPill extends StatelessWidget {
  const CategoryPill({super.key, required this.category, this.large = false});

  final CategoryItem category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8,
        vertical: large ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: category.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: large ? FontWeight.w600 : FontWeight.w500,
          color: category.color,
        ),
      ),
    );
  }
}
