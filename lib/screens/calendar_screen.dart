import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/category_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/task_card.dart';

/// Tab Kalender: grid bulan berjalan dengan titik penanda hari yang punya
/// tugas, lalu daftar tugas untuk tanggal yang dipilih di bawahnya.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.store,
    required this.categories,
    required this.onOpenTask,
  });

  final TaskStore store;
  final CategoryStore categories;
  final ValueChanged<Task> onOpenTask;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  Map<DateTime, int> _taskCountByDay() {
    final counts = <DateTime, int>{};
    for (final task in widget.store.allTasks) {
      final day = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = _taskCountByDay();
    final tasksForDay = widget.store.tasks
        .where((t) => isSameDay(t.dueDate, _selectedDay))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kalender', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.pageText)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: AppColors.pageText),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      formatMonthYear(_visibleMonth),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pageText),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: Icon(Icons.chevron_right_rounded, color: AppColors.pageText),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _MonthGrid(
            visibleMonth: _visibleMonth,
            selectedDay: _selectedDay,
            counts: counts,
            onSelect: (day) => setState(() => _selectedDay = day),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              Text(
                formatFullDate(_selectedDay),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.pageText),
              ),
              const Spacer(),
              Text(
                '${tasksForDay.length} tugas',
                style: TextStyle(fontSize: 13, color: AppColors.pageTextMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasksForDay.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada tugas di tanggal ini',
                    style: TextStyle(fontSize: 14, color: AppColors.pageTextMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  itemCount: tasksForDay.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasksForDay[index];
                    return TaskCard(
                      task: task,
                      category: widget.categories.byId(task.categoryId),
                      onTap: () => widget.onOpenTask(task),
                      onToggle: () => widget.store.toggle(task.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.counts,
    required this.onSelect,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // weekday: Senin=1 ... Minggu=7. Sel kosong sebelum tanggal 1.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[
      for (final label in weekdayLabels)
        Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pageTextMuted),
          ),
        ),
    ];

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final isSelected = isSameDay(date, selectedDay);
      final isToday = date == todayKey;
      final count = counts[date] ?? 0;

      cells.add(
        GestureDetector(
          onTap: () => onSelect(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.pageText,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 4,
                  width: 4,
                  child: count > 0
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}
