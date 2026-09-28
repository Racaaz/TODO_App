import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'notification_service.dart';

/// Menyimpan daftar tugas di memori dan di HP (shared_preferences).
/// Setiap kali tugas ditambah/diubah/dihapus, alarm-nya ikut dijadwalkan
/// ulang lewat NotificationService supaya keduanya selalu sinkron.
class TaskStore extends ChangeNotifier {
  static const _storageKey = 'tasks_v2';

  List<Task> _tasks = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Tugas belum selesai di atas (urut tanggal), yang selesai di bawah.
  List<Task> get tasks {
    final list = [..._tasks];
    list.sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return list;
  }

  /// Daftar mentah tanpa diurutkan (dipakai layar Kalender per tanggal).
  List<Task> get allTasks => List.unmodifiable(_tasks);

  Task? byId(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  List<Task> byCategory(String categoryId) =>
      _tasks.where((t) => t.categoryId == categoryId).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null) {
      // Pertama kali dibuka: isi contoh tugas supaya tampilan tidak kosong.
      _tasks = _sampleTasks();
      await _save();
    } else {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _tasks = list
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _tasks = [];
      }
    }

    _isLoaded = true;
    notifyListeners();
    await _rescheduleAll();
  }

  Future<void> add(Task task) async {
    _tasks.add(task);
    notifyListeners();
    await _save();
    await NotificationService.instance.scheduleForTask(task);
  }

  Future<void> update(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    notifyListeners();
    await _save();
    await NotificationService.instance.scheduleForTask(task);
  }

  Future<void> toggle(String id) async {
    final task = byId(id);
    if (task == null) return;
    await update(task.copyWith(isDone: !task.isDone));
  }

  Future<void> delete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _save();
    await NotificationService.instance.cancelForTask(id);
  }

  /// Menghapus SEMUA tugas (dan alarmnya) tanpa mengisi ulang contoh tugas.
  /// Dipakai dari Profil > Reset Semua Data, dan berguna untuk memastikan
  /// aplikasi benar-benar kosong saat dites ulang setelah build baru.
  Future<void> resetAll() async {
    for (final task in _tasks) {
      await NotificationService.instance.cancelForTask(task.id);
    }
    _tasks = [];
    notifyListeners();
    await _save();
  }

  /// Dipanggil saat kategori dihapus: tugas yang memakainya dipindah ke
  /// kategori Umum supaya tidak yatim piatu.
  Future<void> reassignCategory(String fromId, String toId) async {
    var changed = false;
    _tasks = _tasks.map((t) {
      if (t.categoryId != fromId) return t;
      changed = true;
      return t.copyWith(categoryId: toId);
    }).toList();
    if (changed) {
      notifyListeners();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Dipanggil sekali saat aplikasi dibuka, supaya alarm tetap terjadwal
  /// walau aplikasi sempat ditutup total (dan alarm lama sudah dibersihkan
  /// oleh sistem).
  /// Dipanggil sekali saat aplikasi dibuka (lewat load()), dan bisa dipanggil
  /// lagi kapan pun dari luar, misalnya setelah suara alarm diganti di
  /// Profil, supaya semua tugas dijadwalkan ulang memakai channel/suara baru.
  Future<void> rescheduleAll() => _rescheduleAll();

  Future<void> _rescheduleAll() async {
    for (final task in _tasks) {
      await NotificationService.instance.scheduleForTask(task);
    }
  }

  List<Task> _sampleTasks() {
    final now = DateTime.now();
    DateTime today(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    DateTime inDays(int days, int hour, int minute) => DateTime(
        now.year, now.month, now.day + days, hour, minute);

    return [
      Task(
        id: 'sample-1',
        title: 'Kerjakan laporan praktikum',
        note: 'Selesaikan bab 3 dan 4, lalu kirim ke dosen pembimbing sebelum jam 5 sore.',
        dueDate: today(10, 0),
        priority: TaskPriority.tinggi,
        categoryId: 'kuliah',
      ),
      Task(
        id: 'sample-2',
        title: 'Rapat tim proyek aplikasi',
        dueDate: today(13, 0),
        priority: TaskPriority.tinggi,
        categoryId: 'kerja',
      ),
      Task(
        id: 'sample-3',
        title: 'Beli bahan makanan mingguan',
        dueDate: inDays(1, 16, 30),
        priority: TaskPriority.sedang,
        categoryId: 'belanja',
      ),
      Task(
        id: 'sample-4',
        title: 'Olahraga pagi 30 menit',
        dueDate: today(6, 0),
        priority: TaskPriority.rendah,
        categoryId: 'kesehatan',
        isDone: true,
      ),
      Task(
        id: 'sample-5',
        title: 'Balas email dosen',
        dueDate: today(8, 0),
        priority: TaskPriority.sedang,
        categoryId: 'kuliah',
        isDone: true,
      ),
    ];
  }
}
