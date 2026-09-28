import 'package:flutter/services.dart';

/// Jembatan ke kode native Android (lihat MainActivity.kt).
class FileProviderChannel {
  FileProviderChannel._();
  static const _channel = MethodChannel('todolist/file_provider');

  /// Mendaftarkan suara custom ke MediaStore. [displayName] harus unik per
  /// versi suara (disertakan nomor channelVersion), supaya entri lama yang
  /// mungkin masih dipakai channel yang sudah terkunci tidak ikut terhapus.
  static Future<String?> registerNotificationSound(String path, String displayName) async {
    try {
      return await _channel.invokeMethod<String>(
        'registerNotificationSound',
        {'path': path, 'displayName': displayName},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Membuka layar sistem untuk mengecualikan aplikasi dari pembatasan
  /// baterai, supaya alarm tetap bisa bunyi saat HP terkunci/tidur lama.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final opened = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return opened ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
