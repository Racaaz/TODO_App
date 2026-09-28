import '../models/task.dart';
import 'date_format.dart';

enum TaskFilter {
  semua('Semua'),
  hariIni('Hari ini'),
  mendatang('Mendatang'),
  terlambat('Terlambat'),
  selesai('Selesai');

  const TaskFilter(this.label);
  final String label;

  /// Judul besar di bagian atas layar Tugas.
  String get title => switch (this) {
        TaskFilter.semua => 'Semua Tugas',
        TaskFilter.hariIni => 'Tugas Hari Ini',
        TaskFilter.mendatang => 'Tugas Mendatang',
        TaskFilter.terlambat => 'Tugas Terlambat',
        TaskFilter.selesai => 'Tugas Selesai',
      };
}

/// Aturan filter. Angka di chip, kartu progres, dan daftar semuanya
/// memakai aturan yang sama supaya jumlahnya selalu sinkron.
List<Task> filterTasks(List<Task> all, TaskFilter filter, DateTime now) {
  final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

  switch (filter) {
    case TaskFilter.semua:
      return all;
    case TaskFilter.hariIni:
      return all.where((t) => isSameDay(t.dueDate, now)).toList();
    case TaskFilter.mendatang:
      return all
          .where((t) => !t.isDone && !t.dueDate.isBefore(startOfTomorrow))
          .toList();
    case TaskFilter.terlambat:
      return all.where((t) => !t.isDone && t.dueDate.isBefore(now)).toList();
    case TaskFilter.selesai:
      return all.where((t) => t.isDone).toList();
  }
}

class TaskStats {
  const TaskStats({
    required this.total,
    required this.done,
    required this.overdue,
    required this.todayTotal,
    required this.todayDone,
    required this.upcoming,
    required this.next,
  });

  final int total;
  final int done;
  final int overdue;
  final int todayTotal;
  final int todayDone;
  final int upcoming;

  /// Tugas belum selesai dengan deadline terdekat di masa depan.
  final Task? next;

  factory TaskStats.from(List<Task> tasks, DateTime now) {
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);
    var done = 0;
    var overdue = 0;
    var todayTotal = 0;
    var todayDone = 0;
    var upcoming = 0;
    Task? next;

    for (final t in tasks) {
      if (t.isDone) done++;

      if (isSameDay(t.dueDate, now)) {
        todayTotal++;
        if (t.isDone) todayDone++;
      }

      if (!t.isDone) {
        if (t.dueDate.isBefore(now)) {
          overdue++;
        } else {
          if (!t.dueDate.isBefore(startOfTomorrow)) upcoming++;
          if (next == null || t.dueDate.isBefore(next.dueDate)) next = t;
        }
      }
    }

    return TaskStats(
      total: tasks.length,
      done: done,
      overdue: overdue,
      todayTotal: todayTotal,
      todayDone: todayDone,
      upcoming: upcoming,
      next: next,
    );
  }

  int countFor(TaskFilter filter) => switch (filter) {
        TaskFilter.semua => total,
        TaskFilter.hariIni => todayTotal,
        TaskFilter.mendatang => upcoming,
        TaskFilter.terlambat => overdue,
        TaskFilter.selesai => done,
      };
}
