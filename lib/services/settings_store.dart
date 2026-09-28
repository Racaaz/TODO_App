import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Preferensi tampilan (warna) dan suara alarm, berlaku untuk seluruh
/// aplikasi. Semua digabung dalam satu objek supaya bisa disimpan/dibaca
/// dalam satu kali operasi penyimpanan.
class AppSettings {
  const AppSettings({
    required this.primaryColor,
    required this.backgroundColor,
    required this.soundPath,
    required this.soundLabel,
    required this.defaultReminderOffsets,
    required this.channelVersion,
    required this.displayName,
  });

  final int primaryColor;
  final int backgroundColor;

  /// Path lokal file suara custom di penyimpanan aplikasi sendiri.
  /// null berarti memakai suara notifikasi bawaan sistem.
  final String? soundPath;

  /// Nama file asli, hanya untuk ditampilkan ke pengguna.
  final String? soundLabel;

  /// Menit sebelum deadline untuk pengingat tugas baru (urut menurun).
  /// 0 berarti "tepat saat deadline".
  final List<int> defaultReminderOffsets;

  /// Dinaikkan setiap kali suara alarm diganti, supaya Android membuat
  /// notification channel baru (suara channel Android terkunci setelah dibuat).
  final int channelVersion;

  /// Nama yang ditampilkan di Profil dan avatar layar Home.
  final String displayName;

  static const defaultPrimary = 0xFF4F6BED;
  static const defaultBackground = 0xFFF7F8FA;
  static const defaultOffsets = [1440, 60, 30, 0];

  factory AppSettings.initial() => const AppSettings(
        primaryColor: defaultPrimary,
        backgroundColor: defaultBackground,
        soundPath: null,
        soundLabel: null,
        defaultReminderOffsets: defaultOffsets,
        channelVersion: 1,
        displayName: 'Pengguna',
      );

  AppSettings copyWith({
    int? primaryColor,
    int? backgroundColor,
    String? soundPath,
    String? soundLabel,
    bool clearSound = false,
    List<int>? defaultReminderOffsets,
    int? channelVersion,
    String? displayName,
  }) {
    return AppSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      soundPath: clearSound ? null : (soundPath ?? this.soundPath),
      soundLabel: clearSound ? null : (soundLabel ?? this.soundLabel),
      defaultReminderOffsets: defaultReminderOffsets ?? this.defaultReminderOffsets,
      channelVersion: channelVersion ?? this.channelVersion,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryColor': primaryColor,
        'backgroundColor': backgroundColor,
        'soundPath': soundPath,
        'soundLabel': soundLabel,
        'offsets': defaultReminderOffsets,
        'channelVersion': channelVersion,
        'displayName': displayName,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      primaryColor: (json['primaryColor'] as int?) ?? defaultPrimary,
      backgroundColor: (json['backgroundColor'] as int?) ?? defaultBackground,
      soundPath: json['soundPath'] as String?,
      soundLabel: json['soundLabel'] as String?,
      defaultReminderOffsets: (json['offsets'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          defaultOffsets,
      channelVersion: (json['channelVersion'] as int?) ?? 1,
      displayName: (json['displayName'] as String?) ?? 'Pengguna',
    );
  }
}

class SettingsStore extends ChangeNotifier {
  static const _key = 'app_settings_v1';

  AppSettings _settings = AppSettings.initial();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _settings = AppSettings.initial();
      }
    }
    AppColors.applyFrom(_settings.primaryColor, _settings.backgroundColor);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_settings.toJson()));
  }

  Future<void> setColors({int? primary, int? background}) async {
    _settings = _settings.copyWith(primaryColor: primary, backgroundColor: background);
    AppColors.applyFrom(_settings.primaryColor, _settings.backgroundColor);
    notifyListeners();
    await _save();
  }

  /// Menyalin file suara pilihan pengguna ke folder aplikasi sendiri, supaya
  /// tetap bisa diakses kapan pun tanpa bergantung pada izin file aslinya
  /// (file yang dipilih dari file manager HP bisa saja dipindah/dihapus).
  Future<void> setCustomSound(String sourcePath, String fileLabel) async {
    final dir = await getApplicationDocumentsDirectory();
    final soundsDir = Directory('${dir.path}/sounds');
    if (!await soundsDir.exists()) await soundsDir.create(recursive: true);

    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'mp3';
    final target = File('${soundsDir.path}/custom_alarm.$ext');
    await File(sourcePath).copy(target.path);

    // Bersihkan sisa file suara lama dengan ekstensi berbeda, kalau ada.
    await for (final entity in soundsDir.list()) {
      if (entity is File && entity.path != target.path) {
        try {
          await entity.delete();
        } catch (_) {
          // abaikan, tidak fatal
        }
      }
    }

    _settings = _settings.copyWith(
      soundPath: target.path,
      soundLabel: fileLabel,
      channelVersion: _settings.channelVersion + 1,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    _settings = _settings.copyWith(displayName: trimmed.isEmpty ? 'Pengguna' : trimmed);
    notifyListeners();
    await _save();
  }

  Future<void> clearCustomSound() async {
    _settings = _settings.copyWith(
      clearSound: true,
      channelVersion: _settings.channelVersion + 1,
    );
    notifyListeners();
    await _save();
  }

  Future<void> setDefaultReminderOffsets(List<int> offsets) async {
    final sorted = [...offsets]..sort((a, b) => b.compareTo(a));
    _settings = _settings.copyWith(defaultReminderOffsets: sorted);
    notifyListeners();
    await _save();
  }
}
