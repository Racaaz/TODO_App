import 'package:flutter/services.dart';

/// Jembatan ke alarm native Android (AlarmManager.setAlarmClock +
/// foreground service + MediaPlayer), dipakai KHUSUS untuk alarm
/// tepat-deadline supaya suaranya tetap bunyi walau layar mati/terkunci.
/// flutter_local_notifications tetap dipakai untuk pengingat
/// sebelum-deadline yang sifatnya tidak sekritis itu.
class NativeAlarmChannel {
  NativeAlarmChannel._();
  static const _channel = MethodChannel('todolist/file_provider');

  static Future<bool> schedule({
    required int requestCode,
    required DateTime triggerAt,
    required String title,
    String? soundPath,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('scheduleNativeAlarm', {
        'requestCode': requestCode,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
        'title': title,
        'soundPath': soundPath,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<void> cancel(int requestCode) async {
    try {
      await _channel.invokeMethod('cancelNativeAlarm', {'requestCode': requestCode});
    } on PlatformException {
      // abaikan, tidak fatal
    } on MissingPluginException {
      // abaikan, tidak fatal
    }
  }
}
