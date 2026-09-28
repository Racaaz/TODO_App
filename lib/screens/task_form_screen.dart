import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/task.dart';
import '../services/category_store.dart';
import '../services/settings_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import '../theme/task_style.dart';
import '../utils/date_format.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/category_pill.dart';
import '../widgets/reminder_offsets_editor.dart';
import '../widgets/screen_top_bar.dart';

/// Layar untuk menambah tugas baru. Kalau [task] diisi, layar ini menjadi mode edit.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({
    super.key,
    required this.store,
    required this.categories,
    required this.settingsStore,
    this.task,
  });

  final TaskStore store;
  final CategoryStore categories;
  final SettingsStore settingsStore;
  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late TimeOfDay _time;
  late TaskPriority _priority;
  late String _categoryId;
  late bool _alarmEnabled;
  late List<int> _reminderOffsets;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final now = DateTime.now();
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _date = task?.dueDate ?? now;
    _time = TimeOfDay.fromDateTime(task?.dueDate ?? now);
    _priority = task?.priority ?? TaskPriority.sedang;
    _categoryId = task?.categoryId ?? widget.categories.categories.first.id;
    _alarmEnabled = task?.alarmEnabled ?? true;
    _reminderOffsets = List<int>.from(
      task?.reminderOffsetsMinutes ?? widget.settingsStore.settings.defaultReminderOffsets,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(
      context,
      store: widget.categories,
      selectedId: _categoryId,
    );
    if (picked != null) setState(() => _categoryId = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final dueDate = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final existing = widget.task;

    if (existing == null) {
      widget.store.add(
        Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          note: note,
          dueDate: dueDate,
          priority: _priority,
          categoryId: _categoryId,
          alarmEnabled: _alarmEnabled,
          reminderOffsetsMinutes: _reminderOffsets,
        ),
      );
    } else {
      widget.store.update(
        existing.copyWith(
          title: title,
          note: note,
          dueDate: dueDate,
          priority: _priority,
          categoryId: _categoryId,
          alarmEnabled: _alarmEnabled,
          reminderOffsetsMinutes: _reminderOffsets,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.categories,
      builder: (context, _) {
        final category = widget.categories.categories
            .firstWhere((c) => c.id == _categoryId, orElse: () => defaultCategories.last);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ScreenTopBar(title: _isEditing ? 'Edit Tugas' : 'Tugas Baru'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Judul tugas'),
                          TextFormField(
                            controller: _titleController,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputDecoration('Contoh: Kerjakan laporan'),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Judul tugas wajib diisi' : null,
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Catatan (opsional)'),
                          TextFormField(
                            controller: _noteController,
                            minLines: 3,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(fontSize: 16),
                            decoration: _inputDecoration('Tulis detail tugas di sini...'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _PickerField(
                                  label: 'Tanggal',
                                  icon: Icons.calendar_today_outlined,
                                  value: formatShortDate(_date),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PickerField(
                                  label: 'Waktu',
                                  icon: Icons.access_time_rounded,
                                  value: formatTimeOfDay(_time),
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Prioritas'),
                          Row(
                            children: [
                              for (final p in TaskPriority.values)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: p == TaskPriority.tinggi ? 0 : 8),
                                    child: _PriorityChip(
                                      priority: p,
                                      selected: _priority == p,
                                      onTap: () => setState(() => _priority = p),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Kategori'),
                          GestureDetector(
                            onTap: _pickCategory,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  CategoryPill(category: category, large: true),
                                  const Spacer(),
                                  const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                              color: Colors.white,
                            ),
                            child: SwitchListTile(
                              value: _alarmEnabled,
                              onChanged: (value) => setState(() => _alarmEnabled = value),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              title: const Text(
                                'Alarm pengingat deadline',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                _reminderOffsets.isEmpty
                                    ? 'Belum ada waktu pengingat diatur'
                                    : '${_reminderOffsets.length} kali pengingat diatur',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                          if (_alarmEnabled) ...[
                            const SizedBox(height: 12),
                            const _FieldLabel('Alarm akan berbunyi pada'),
                            ReminderOffsetsEditor(
                              offsets: _reminderOffsets,
                              onChanged: (value) => setState(() => _reminderOffsets = value),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Tugas'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

OutlineInputBorder _border(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: _border(AppColors.border),
    enabledBorder: _border(AppColors.border),
    focusedBorder: _border(AppColors.primary, 1.5),
    errorBorder: _border(AppColors.danger),
    focusedErrorBorder: _border(AppColors.danger, 1.5),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.pageTextMuted),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.icon, required this.value, required this.onTap});

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority, required this.selected, required this.onTap});

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? priority.background : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? priority.color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: priority.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              priority.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? priority.foreground : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
