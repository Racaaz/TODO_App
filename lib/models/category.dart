import 'package:flutter/material.dart';

/// Id kategori yang dipakai kalau kategori sebuah tugas tidak ditemukan / dihapus.
const String defaultCategoryId = 'umum';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int colorValue;

  /// Kategori bawaan tidak bisa diubah atau dihapus.
  final bool isDefault;

  Color get color => Color(colorValue);

  /// Warna latar lembut yang diturunkan dari warna utama kategori.
  Color get background =>
      Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white);

  CategoryItem copyWith({String? name, int? colorValue}) {
    return CategoryItem(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['color'] as int,
    );
  }
}

/// Kategori bawaan (id-nya sama dengan versi sebelumnya, jadi data lama tetap cocok).
const List<CategoryItem> defaultCategories = [
  CategoryItem(id: 'kuliah', name: 'Kuliah', colorValue: 0xFF4F6BED, isDefault: true),
  CategoryItem(id: 'kerja', name: 'Kerja', colorValue: 0xFF0369A1, isDefault: true),
  CategoryItem(id: 'belanja', name: 'Belanja', colorValue: 0xFFB45309, isDefault: true),
  CategoryItem(id: 'kesehatan', name: 'Kesehatan', colorValue: 0xFF15803D, isDefault: true),
  CategoryItem(id: defaultCategoryId, name: 'Umum', colorValue: 0xFF475569, isDefault: true),
];

/// Pilihan warna untuk kategori buatan sendiri (semuanya cukup gelap agar teks terbaca).
const List<int> categoryColorChoices = [
  0xFF4F6BED,
  0xFF0369A1,
  0xFF0F766E,
  0xFF15803D,
  0xFFB45309,
  0xFFC2410C,
  0xFFB91C1C,
  0xFFBE185D,
  0xFF7E22CE,
  0xFF475569,
];
