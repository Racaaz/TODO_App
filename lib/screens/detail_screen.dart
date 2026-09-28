import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/category_store.dart';
import '../services/settings_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import '../theme/task_style.dart';
import '../utils/date_format.dart';
import '../utils/deadline.dart';
import '../widgets/category_pill.dart';
import '../widgets/screen_top_bar.dart';
import 'task_form_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.store,
    required this.categories,
    required this.settingsStore,
    required this.taskId,
  });

  final TaskStore store;
  final CategoryStore categories;
  final SettingsStore settingsStore;
  final String taskId;

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${task.title}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      store.delete(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, categories]),
      builder: (context, _) {
        final task = store.byId(taskId);
        if (task == null) return const Scaffold();
        final category = categories.byId(task.categoryId);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Detail Tugas',
                  trailing: CircleIconButton(
                    icon: Icons.delete_outline_rounded,
                    background: AppColors.dangerSoft,
                    iconColor: AppColors.danger,
                    bordered: false,
                    onPressed: () => _confirmDelete(context, task),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryPill(category: category, large: true),
                        const SizedBox(height: 12),
                        Text(
                          task.title,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.pageText),
                        ),
                        const SizedBox(height: 8),
                        _RemainingBanner(task: task),
                        const SizedBox(height: 20),
                        _InfoCard(task: task),
                        const SizedBox(height: 20),
                        _NotesCard(note: task.note),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TaskFormScreen(
                                  store: store,
                                  categories: categories,
                                  settingsStore: settingsStore,
                                  task: task,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => store.toggle(task.id),
                          icon: Icon(task.isDone ? Icons.undo_rounded : Icons.check_rounded, size: 18),
                          label: Text(task.isDone ? 'Tandai Belum Selesai' : 'Tandai Selesai'),
                        ),
                      ),
                    ],
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

class _RemainingBanner extends StatelessWidget {
  const _RemainingBanner({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    if (task.isDone) return const SizedBox.shrink();
    final now = DateTime.now();
    final text = formatRemaining(task.dueDate, now);
    final overdue = task.dueDate.isBefore(now);

    return Row(
      children: [
        Icon(
          overdue ? Icons.error_outline_rounded : Icons.alarm_rounded,
          size: 16,
          color: overdue ? AppColors.danger : AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: overdue ? AppColors.danger : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color tint;
  final String label;
  final String value;
  final Color valueColor;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRowData(
        icon: Icons.calendar_today_outlined,
        iconColor: AppColors.primary,
        tint: AppColors.primarySoft,
        label: 'Tanggal',
        value: formatFullDate(task.dueDate),
        valueColor: AppColors.textPrimary,
      ),
      _InfoRowData(
        icon: Icons.access_time_rounded,
        iconColor: const Color(0xFF0369A1),
        tint: const Color(0xFFE0F2FE),
        label: 'Waktu',
        value: formatTime(task.dueDate),
        valueColor: AppColors.textPrimary,
      ),
      _InfoRowData(
        icon: Icons.flag_outlined,
        iconColor: task.priority.color,
        tint: task.priority.background,
        label: 'Prioritas',
        value: task.priority.label,
        valueColor: task.priority.foreground,
      ),
      _InfoRowData(
        icon: task.alarmEnabled ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
        iconColor: task.alarmEnabled ? AppColors.success : AppColors.textMuted,
        tint: task.alarmEnabled ? AppColors.successSoft : AppColors.background,
        label: 'Alarm',
        value: task.alarmEnabled
            ? '${task.reminderOffsetsMinutes.length} kali pengingat'
            : 'Nonaktif',
        valueColor: AppColors.textPrimary,
      ),
      _InfoRowData(
        icon: Icons.check_circle_outline_rounded,
        iconColor: task.isDone ? const Color(0xFF15803D) : const Color(0xFFF59E0B),
        tint: task.isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        label: 'Status',
        value: task.isDone ? 'Selesai' : 'Belum selesai',
        valueColor: AppColors.textPrimary,
      ),
    ];

    return Container(
      decoration: AppDecorations.card(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(data: rows[i]),
            if (i < rows.length - 1) const Divider(height: 1, thickness: 1, color: Color(0xFFF1F2F5)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: data.tint, borderRadius: BorderRadius.circular(12)),
            child: Icon(data.icon, size: 20, color: data.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(data.value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: data.valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final hasNote = note.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            hasNote ? note : 'Tidak ada catatan',
            style: TextStyle(fontSize: 15, height: 1.45, color: hasNote ? const Color(0xFF4B5563) : AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
