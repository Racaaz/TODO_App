import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../utils/reminder_format.dart';
import 'file_provider_channel.dart';
import 'native_alarm_channel.dart';
import 'settings_store.dart';

/// Membungkus flutter_local_notifications. Satu tugas bisa punya BEBERAPA
/// alarm (satu per nilai di task.reminderOffsetsMinutes), masing-masing
/// dengan id sendiri (id dasar dari hash id tugas, ditambah nomor urut).
/// Menjadwalkan ulang selalu membatalkan dulu semua kemungkinan id lama
/// untuk tugas itu, supaya tidak ada alarm nyasar ketika daftar pengingat
/// diperpendek.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelName = 'Pengingat Deadline Tugas';
  static const _channelDescription =
      'Alarm yang muncul saat deadline tugas sudah dekat atau tiba';

  /// Maksimum pengingat per tugas (membatasi rentang id supaya antar-tugas
  /// tidak bertabrakan).
  static const _maxRemindersPerTask = 12;

  /// Selisih id untuk alarm native tepat-deadline, masih di dalam "jatah"
  /// 100 id milik tiap tugas (0..11 dipakai notifikasi biasa).
  static const _nativeAlarmOffset = 50;

  bool _initialized = false;
  bool _timezoneReady = false;
  AppSettings _appSettings = AppSettings.initial();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_guessLocalLocation());
    _timezoneReady = true;

    if (!_initialized) {
      _initialized = true;
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _plugin.initialize(settings: settings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }

    await _ensureChannel();
  }

  /// Dipanggil dari SettingsStore setiap kali preferensi berubah. Kalau
  /// channelVersion naik (berarti suara baru diganti), channel Android
  /// dibuat ulang dengan suara yang baru.
  Future<void> applySettings(AppSettings settings) async {
    final soundChanged = settings.channelVersion != _appSettings.channelVersion;
    _appSettings = settings;
    if (soundChanged && _timezoneReady) {
      await _ensureChannel();
    }
  }

  // Prefix diubah dari 'task_deadline_channel_v' supaya update ini (yang
  // menambahkan audioAttributesUsage: alarm) membuat channel BENAR-BENAR
  // baru, bukan memakai channel lama yang sudah terkunci ke pengaturan lama.
  String get _channelId => 'task_deadline_channel_alarm_v${_appSettings.channelVersion}';

  Future<void> _ensureChannel() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    AndroidNotificationSound? sound;
    final soundPath = _appSettings.soundPath;
    if (soundPath != null && await File(soundPath).exists()) {
      final displayName = 'todo_alarm_sound_v${_appSettings.channelVersion}.mp3';
      final uri = await FileProviderChannel.registerNotificationSound(soundPath, displayName);
      if (uri != null) sound = UriAndroidNotificationSound(uri);
    }

    await androidImpl.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: sound, // null = suara notifikasi bawaan sistem
        enableVibration: true,
        // Diperlakukan sebagai suara ALARM (bukan notifikasi biasa), supaya
        // durasinya diputar penuh. Banyak HP (terutama MIUI) memotong
        // pendek suara notifikasi biasa jadi hanya sekitar 1 detik.
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    // Hapus channel versi sebelumnya, supaya daftar notifikasi di
    // Pengaturan HP tidak menumpuk setiap kali suara diganti.
    final previousVersion = _appSettings.channelVersion - 1;
    if (previousVersion >= 1) {
      try {
        await androidImpl.deleteNotificationChannel(channelId: 'task_deadline_channel_alarm_v$previousVersion');
      } catch (_) {
        // abaikan, tidak fatal kalau channel lama tidak ada
      }
    }
  }

  tz.Location _guessLocalLocation() {
    final offset = DateTime.now().timeZoneOffset;
    final candidates = <Duration, String>{
      const Duration(hours: 7): 'Asia/Jakarta',
      const Duration(hours: 8): 'Asia/Makassar',
      const Duration(hours: 9): 'Asia/Jayapura',
    };
    final name = candidates[offset];
    if (name != null) {
      try {
        return tz.getLocation(name);
      } catch (_) {
        // fall through
      }
    }
    try {
      return tz.getLocation(
          'Etc/GMT${offset.isNegative ? '+' : '-'}${offset.inHours.abs()}');
    } catch (_) {
      return tz.UTC;
    }
  }

  int _baseIdFor(String taskId) =>
      (taskId.hashCode & 0x7fffffff) - ((taskId.hashCode & 0x7fffffff) % 100);

  /// Menjadwalkan semua alarm untuk satu tugas sesuai
  /// task.reminderOffsetsMinutes. Alarm yang waktunya sudah lewat dilewati.
  Future<void> scheduleForTask(Task task) async {
    await cancelForTask(task.id);
    if (!task.alarmEnabled || task.isDone) return;
    if (!_timezoneReady) await init();

    final baseId = _baseIdFor(task.id);
    final now = tz.TZDateTime.now(tz.local);
    final offsets = task.reminderOffsetsMinutes.isEmpty
        ? const [0]
        : task.reminderOffsetsMinutes.take(_maxRemindersPerTask).toList();

    for (var i = 0; i < offsets.length; i++) {
      final minutes = offsets[i];
      final due = tz.TZDateTime.from(task.dueDate, tz.local)
          .subtract(Duration(minutes: minutes));
      if (!due.isAfter(now)) continue;

      final isAtDeadline = minutes <= 0;

      if (isAtDeadline) {
        // Alarm tepat-deadline: pakai alarm NATIVE (setAlarmClock + service
        // + MediaPlayer jalur ALARM) supaya suaranya pasti bunyi walau
        // layar mati/terkunci. Kalau gagal (mis. bukan Android), jatuh
        // kembali ke notifikasi biasa di bawah.
        final scheduled = await NativeAlarmChannel.schedule(
          requestCode: baseId + _nativeAlarmOffset,
          triggerAt: task.dueDate,
          title: '⏰ Waktunya: ${task.title}',
          soundPath: _appSettings.soundPath,
        );
        if (scheduled) continue;
      }

      await _schedule(
        id: baseId + i,
        title: isAtDeadline ? '⏰ Waktunya: ${task.title}' : 'Pengingat: ${task.title}',
        body: isAtDeadline
            ? 'Tugas ini sudah mencapai batas waktu sekarang.'
            : 'Deadline tugas ini ${formatOffsetLabel(minutes)} lagi.',
        date: due,
        fullScreen: isAtDeadline,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    required bool fullScreen,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: date,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: fullScreen,
            playSound: true,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            // Untuk alarm tepat-deadline (fullScreen): jangan biarkan
            // notifikasinya otomatis "ditutup" begitu layar menyala, karena
            // itu ikut memotong paksa suara yang sedang diputar.
            ongoing: fullScreen,
            autoCancel: !fullScreen,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } on PlatformException catch (e) {
      // Izin exact alarm belum diberikan pengguna: alarm dilewati diam-diam
      // supaya aplikasi tidak crash. UI tetap berjalan normal.
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }

  /// Membatalkan semua kemungkinan id alarm untuk satu tugas (mencakup
  /// _maxRemindersPerTask id sekaligus, supaya aman walau daftar
  /// pengingatnya baru saja diperpendek dari yang sebelumnya).
  Future<void> cancelForTask(String taskId) async {
    final baseId = _baseIdFor(taskId);
    for (var i = 0; i < _maxRemindersPerTask; i++) {
      await _plugin.cancel(id: baseId + i);
    }
    await NativeAlarmChannel.cancel(baseId + _nativeAlarmOffset);
  }

  bool get supportsExactAlarms => Platform.isAndroid || Platform.isIOS;
}
