import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/category_store.dart';
import 'services/notification_service.dart';
import 'services/settings_store.dart';
import 'services/task_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  // Gudang data yang dipakai bersama oleh semua layar.
  final SettingsStore _settingsStore = SettingsStore();
  final CategoryStore _categories = CategoryStore();
  final TaskStore _store = TaskStore();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Urutan ini penting: pengaturan (warna & suara) dimuat dan diterapkan
    // dulu, baru notifikasi diinisialisasi (supaya channel langsung dibuat
    // dengan suara yang benar), baru kategori, baru tugas (yang langsung
    // menjadwalkan alarm saat load()).
    await _settingsStore.load();
    await NotificationService.instance.applySettings(_settingsStore.settings);
    await NotificationService.instance.init();
    await _categories.load();
    await _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    _categories.dispose();
    _settingsStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settingsStore,
      builder: (context, _) {
        // AppColors sudah dimutakhirkan oleh SettingsStore setiap kali
        // preferensi berubah, jadi buildAppTheme() di sini selalu memakai
        // warna terbaru.
        return MaterialApp(
          title: 'To Do List',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: HomeScreen(store: _store, categories: _categories, settingsStore: _settingsStore),
        );
      },
    );
  }
}
