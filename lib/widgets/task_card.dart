import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../theme/task_style.dart';
import '../utils/date_format.dart';
import '../utils/deadline.dart';
import 'category_pill.dart';

/// Komponen "Task Card" dari Figma, ditambah label sisa waktu saat
/// deadline sudah dekat atau terlewat.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.category,
    required this.onTap,
    required this.onToggle,
    this.now,
  });

  final Task task;
  final CategoryItem category;
  final VoidCallback onTap; // ketuk kartu -> buka detail
  final VoidCallback onToggle; // ketuk checkbox -> tandai selesai
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final deadline = deadlineInfo(task, now ?? DateTime.now());

    return Opacity(
      opacity: done ? 0.7 : 1,
      child: Container(
        decoration: AppDecorations.card(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _CheckBox(checked: done, onTap: onToggle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formatTime(task.dueDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            CategoryPill(category: category),
                            if (deadline != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: deadline.overdue
                                      ? AppColors.dangerSoft
                                      : AppColors.warningSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      deadline.overdue
                                          ? Icons.error_outline_rounded
                                          : Icons.alarm_rounded,
                                      size: 12,
                                      color: deadline.overdue
                                          ? AppColors.danger
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      deadline.text,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: deadline.overdue
                                            ? AppColors.danger
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: checked ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: checked
                ? null
                : Border.all(color: AppColors.checkboxBorder, width: 2),
          ),
          child: checked
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
