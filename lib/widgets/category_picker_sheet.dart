import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/category_store.dart';
import '../theme/app_theme.dart';

/// Bottom sheet untuk memilih kategori, dengan tombol "Kategori baru" di
/// bagian bawah supaya pengguna bisa membuat kategori tanpa pindah layar.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required CategoryStore store,
  required String selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) => _CategoryPickerSheet(
      store: store,
      selectedId: selectedId,
    ),
  );
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.store, required this.selectedId});

  final CategoryStore store;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in store.categories)
                      _CategoryOption(
                        category: c,
                        selected: c.id == selectedId,
                        onTap: () => Navigator.of(context).pop(c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final created = await showEditCategoryDialog(context, store);
                    if (created != null && context.mounted) {
                      Navigator.of(context).pop(created.id);
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Kategori Baru'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryItem category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? category.background : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? category.color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? category.color : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog tambah/edit kategori (nama + pilihan warna). Dipakai dari sheet di
/// atas maupun dari layar Kategori.
Future<CategoryItem?> showEditCategoryDialog(
  BuildContext context,
  CategoryStore store, {
  CategoryItem? existing,
}) {
  return showDialog<CategoryItem>(
    context: context,
    builder: (context) => _EditCategoryDialog(store: store, existing: existing),
  );
}

class _EditCategoryDialog extends StatefulWidget {
  const _EditCategoryDialog({required this.store, this.existing});

  final CategoryStore store;
  final CategoryItem? existing;

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController _nameController;
  late int _color;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.colorValue ?? categoryColorChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama kategori wajib diisi');
      return;
    }
    final isDuplicate = widget.store.categories.any((c) =>
        c.id != widget.existing?.id &&
        c.name.toLowerCase() == name.toLowerCase());
    if (isDuplicate) {
      setState(() => _error = 'Kategori dengan nama ini sudah ada');
      return;
    }

    if (widget.existing == null) {
      final created = await widget.store.add(name, _color);
      if (mounted) Navigator.of(context).pop(created);
    } else {
      await widget.store.update(widget.existing!.id, name: name, colorValue: _color);
      if (mounted) {
        Navigator.of(context).pop(widget.existing!.copyWith(name: name, colorValue: _color));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Kategori' : 'Kategori Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Contoh: Skripsi, Hobi, Keuangan',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            const Text('Warna', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final value in categoryColorChoices)
                  GestureDetector(
                    onTap: () => setState(() => _color = value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == value
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _color == value
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
