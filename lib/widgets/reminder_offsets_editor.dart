import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/reminder_format.dart';

/// Daftar chip waktu pengingat (misalnya "1 hari", "30 menit", "Tepat waktu")
/// dengan tombol hapus di tiap chip dan tombol "+ Tambah" untuk menambah
/// pengingat baru. Dipakai di form tugas (per tugas) dan di Profil (default
/// untuk tugas baru).
class ReminderOffsetsEditor extends StatelessWidget {
  const ReminderOffsetsEditor({
    super.key,
    required this.offsets,
    required this.onChanged,
  });

  final List<int> offsets;
  final ValueChanged<List<int>> onChanged;

  Future<void> _addReminder(BuildContext context) async {
    final picked = await showAddReminderDialog(context, existing: offsets);
    if (picked == null) return;
    if (offsets.contains(picked)) return;
    final updated = [...offsets, picked]..sort((a, b) => b.compareTo(a));
    onChanged(updated);
  }

  void _remove(int value) {
    onChanged(offsets.where((o) => o != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...offsets]..sort((a, b) => b.compareTo(a));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in sorted)
          Container(
            padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatOffsetChip(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _remove(value),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 15, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: () => _addReminder(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  'Tambah',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Belum ada pengingat. Ketuk "Tambah" untuk menambah.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Dialog untuk memilih satu waktu pengingat baru: preset cepat, atau
/// nilai custom (angka + satuan menit/jam/hari).
Future<int?> showAddReminderDialog(BuildContext context, {required List<int> existing}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _AddReminderDialog(existing: existing),
  );
}

class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog({required this.existing});

  final List<int> existing;

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final _amountController = TextEditingController(text: '30');
  String _unit = 'menit';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? get _customMinutes {
    final n = int.tryParse(_amountController.text.trim());
    if (n == null || n <= 0) return null;
    return switch (_unit) {
      'jam' => n * 60,
      'hari' => n * 1440,
      _ => n,
    };
  }

  @override
  Widget build(BuildContext context) {
    final presets = reminderPresets.where((p) => !widget.existing.contains(p)).toList();

    return AlertDialog(
      title: const Text('Tambah Pengingat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilihan cepat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in presets)
                  ActionChip(
                    label: Text(formatOffsetChip(p)),
                    onPressed: () => Navigator.of(context).pop(p),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Atau atur sendiri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _unit,
                  items: const [
                    DropdownMenuItem(value: 'menit', child: Text('menit')),
                    DropdownMenuItem(value: 'jam', child: Text('jam')),
                    DropdownMenuItem(value: 'hari', child: Text('hari')),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? 'menit'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Sebelum waktu deadline tugas',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        FilledButton(
          onPressed: _customMinutes == null
              ? null
              : () => Navigator.of(context).pop(_customMinutes),
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
