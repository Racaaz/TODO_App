import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';

/// Menyimpan daftar kategori (bawaan + buatan pengguna) di HP.
class CategoryStore extends ChangeNotifier {
  static const _storageKey = 'categories_v1';

  List<CategoryItem> _categories = [...defaultCategories];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<CategoryItem> get categories => List.unmodifiable(_categories);

  CategoryItem byId(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    // Kategori tugas ini sudah dihapus: jatuhkan ke kategori Umum.
    return _categories.firstWhere(
      (c) => c.id == defaultCategoryId,
      orElse: () => defaultCategories.last,
    );
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final saved = list
            .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        // Kategori bawaan tetap dipakai dari kode (supaya warnanya konsisten
        // walau app di-update), lalu ditambah kategori buatan pengguna.
        final customOnes = saved.where((c) => !c.isDefault).toList();
        _categories = [...defaultCategories, ...customOnes];
      } catch (_) {
        _categories = [...defaultCategories];
      }
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<CategoryItem> add(String name, int colorValue) async {
    final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    final category = CategoryItem(id: id, name: name, colorValue: colorValue);
    _categories.add(category);
    notifyListeners();
    await _save();
    return category;
  }

  Future<void> update(String id, {String? name, int? colorValue}) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1 || _categories[index].isDefault) return;
    _categories[index] =
        _categories[index].copyWith(name: name, colorValue: colorValue);
    notifyListeners();
    await _save();
  }

  /// Menghapus kategori buatan pengguna. Mengembalikan false kalau kategori
  /// itu bawaan (tidak boleh dihapus).
  Future<bool> delete(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1 || _categories[index].isDefault) return false;
    _categories.removeAt(index);
    notifyListeners();
    await _save();
    return true;
  }

  /// Menghapus semua kategori buatan pengguna, menyisakan kategori bawaan
  /// saja. Dipakai dari Profil > Reset Semua Data.
  Future<void> resetToDefaults() async {
    _categories = [...defaultCategories];
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final customOnly = _categories.where((c) => !c.isDefault).toList();
    final encoded = jsonEncode(customOnly.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
