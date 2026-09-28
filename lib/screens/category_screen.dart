import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import '../widgets/category_picker_sheet.dart';

/// Tab Kategori: daftar semua kategori dengan jumlah tugasnya, dan tombol
/// untuk membuat, mengedit, atau menghapus kategori buatan pengguna.
/// Kategori bawaan (Kuliah, Kerja, Belanja, Kesehatan, Umum) tidak bisa
/// dihapus supaya data lama tetap punya tempat.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.store, required this.categories});

  final TaskStore store;
  final CategoryStore categories;

  Future<void> _createCategory(BuildContext context) async {
    await showEditCategoryDialog(context, categories);
  }

  Future<void> _editCategory(BuildContext context, CategoryItem category) async {
    await showEditCategoryDialog(context, categories, existing: category);
  }

  Future<void> _deleteCategory(BuildContext context, CategoryItem category) async {
    final taskCount = store.byCategory(category.id).length;
    final message = taskCount == 0
        ? 'Kategori "${category.name}" akan dihapus.'
        : 'Kategori "${category.name}" akan dihapus. $taskCount tugas di dalamnya akan dipindah ke kategori Umum.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (taskCount > 0) {
        await store.reassignCategory(category.id, defaultCategoryId);
      }
      await categories.delete(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, categories]),
      builder: (context, _) {
        final list = categories.categories;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kategori', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.pageText)),
                  FilledButton.icon(
                    onPressed: () => _createCategory(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Baru'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = list[index];
                  final taskCount = store.byCategory(category.id).length;
                  return _CategoryTile(
                    category: category,
                    taskCount: taskCount,
                    onEdit: category.isDefault ? null : () => _editCategory(context, category),
                    onDelete: category.isDefault ? null : () => _deleteCategory(context, category),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.taskCount,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryItem category;
  final int taskCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: category.background, shape: BoxShape.circle),
            child: Icon(Icons.label_rounded, size: 20, color: category.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '$taskCount tugas${category.isDefault ? ' · Bawaan' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}
