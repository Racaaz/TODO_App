import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/category_store.dart';
import '../services/settings_store.dart';
import '../services/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/initials.dart';
import '../utils/task_stats.dart';
import '../widgets/task_card.dart';
import 'calendar_screen.dart';
import 'category_screen.dart';
import 'detail_screen.dart';
import 'profile_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.categories,
    required this.settingsStore,
  });

  final TaskStore store;
  final CategoryStore categories;
  final SettingsStore settingsStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  TaskFilter _filter = TaskFilter.semua;

  // Diperbarui tiap menit supaya label "X menit lagi" dan angka
  // "Hari ini" tetap akurat tanpa harus membuka ulang aplikasi.
  late DateTime _now;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _openForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskFormScreen(
          store: widget.store,
          categories: widget.categories,
          settingsStore: widget.settingsStore,
        ),
      ),
    );
  }

  void _openDetail(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(
          store: widget.store,
          categories: widget.categories,
          settingsStore: widget.settingsStore,
          taskId: task.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.store, widget.categories, widget.settingsStore]),
      builder: (context, _) {
        if (!widget.store.isLoaded || !widget.categories.isLoaded || !widget.settingsStore.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final body = switch (_tab) {
          1 => CalendarScreen(
              store: widget.store,
              categories: widget.categories,
              onOpenTask: _openDetail,
            ),
          2 => CategoryScreen(store: widget.store, categories: widget.categories),
          3 => ProfileScreen(store: widget.store, categories: widget.categories, settingsStore: widget.settingsStore),
          _ => _TaskListBody(
              store: widget.store,
              categories: widget.categories,
              settingsStore: widget.settingsStore,
              filter: _filter,
              now: _now,
              onFilterChanged: (f) => setState(() => _filter = f),
              onAdd: _openForm,
              onOpenTask: _openDetail,
            ),
        };

        return Scaffold(
          body: SafeArea(bottom: false, child: body),
          floatingActionButton: _tab == 0 && widget.store.allTasks.isNotEmpty
              ? FloatingActionButton(
                  onPressed: _openForm,
                  tooltip: 'Tambah tugas',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add_rounded, size: 28),
                )
              : null,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_rounded),
                  label: 'Tugas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Kalender',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Kategori',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskListBody extends StatelessWidget {
  const _TaskListBody({
    required this.store,
    required this.categories,
    required this.settingsStore,
    required this.filter,
    required this.now,
    required this.onFilterChanged,
    required this.onAdd,
    required this.onOpenTask,
  });

  final TaskStore store;
  final CategoryStore categories;
  final SettingsStore settingsStore;
  final TaskFilter filter;
  final DateTime now;
  final ValueChanged<TaskFilter> onFilterChanged;
  final VoidCallback onAdd;
  final ValueChanged<Task> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final all = store.tasks;
    final stats = TaskStats.from(all, now);
    // Satu fungsi filter dipakai baik untuk daftar maupun untuk angka di
    // setiap chip, jadi keduanya selalu sinkron.
    final visible = filterTasks(all, filter, now);

    if (all.isEmpty) {
      return Column(
        children: [
          _Header(displayName: settingsStore.settings.displayName),
          Expanded(child: _EmptyState(onAdd: onAdd)),
        ],
      );
    }

    return Column(
      children: [
        _Header(displayName: settingsStore.settings.displayName),
        _ProgressCard(stats: stats),
        _FilterBar(stats: stats, selected: filter, onSelected: onFilterChanged),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada tugas di daftar ini',
                    style: TextStyle(fontSize: 15, color: AppColors.pageTextMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = visible[index];
                    return TaskCard(
                      task: task,
                      category: categories.byId(task.categoryId),
                      now: now,
                      onTap: () => onOpenTask(task),
                      onToggle: () => store.toggle(task.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatFullDate(DateTime.now()),
            style: TextStyle(fontSize: 14, color: AppColors.pageTextMuted),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tugas Hari Ini',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.pageText),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryTint,
                child: Text(
                  initialsFromName(displayName),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stats});

  final TaskStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.todayTotal;
    final done = stats.todayDone;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progres hari ini',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              total == 0 ? 'Tidak ada tugas hari ini' : '$done dari $total tugas selesai',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            if (stats.overdue > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${stats.overdue} tugas terlambat',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.stats, required this.selected, required this.onSelected});

  final TaskStats stats;
  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Row(
        children: [
          for (final filter in TaskFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: filter.label,
                count: stats.countFor(filter),
                selected: filter == selected,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.25) : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                child: Icon(Icons.assignment_outlined, size: 44, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text('Belum ada tugas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.pageText)),
            const SizedBox(height: 8),
            Text(
              'Ketuk tombol di bawah untuk menambahkan tugas pertama Anda dan mulai atur harimu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.45, color: AppColors.pageTextMuted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tambah Tugas'),
            ),
          ],
        ),
      ),
    );
  }
}
