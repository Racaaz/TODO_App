package com.example.to_do_list

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "todolist/file_provider"
    private val SOUND_DISPLAY_NAME = "todo_alarm_sound.mp3"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerNotificationSound" -> {
                    val path = call.argument<String>("path")
                    val displayName = call.argument<String>("displayName") ?: SOUND_DISPLAY_NAME
                    if (path == null) {
                        result.error("NO_PATH", "Path tidak diberikan", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(registerSoundInMediaStore(path, displayName))
                    } catch (e: Exception) {
                        result.error("MEDIASTORE_ERROR", e.message, null)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                intent.data = Uri.parse("package:$packageName")
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "scheduleNativeAlarm" -> {
                    try {
                        val requestCode = call.argument<Int>("requestCode") ?: 0
                        val triggerAtMillis = call.argument<Number>("triggerAtMillis")?.toLong() ?: 0L
                        val title = call.argument<String>("title") ?: "Waktunya!"
                        val soundPath = call.argument<String>("soundPath")

                        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
                        val receiverIntent = Intent(this, AlarmReceiver::class.java).apply {
                            putExtra("title", title)
                            putExtra("soundPath", soundPath)
                        }
                        val alarmPending = PendingIntent.getBroadcast(
                            this, requestCode, receiverIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        val showPending = PendingIntent.getActivity(
                            this, requestCode, Intent(this, MainActivity::class.java),
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        // setAlarmClock = API khusus "jam alarm" sungguhan: kebal Doze dan
                        // pembatasan baterai, dan dijamin berbunyi tepat waktu.
                        alarmManager.setAlarmClock(
                            AlarmManager.AlarmClockInfo(triggerAtMillis, showPending),
                            alarmPending
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "cancelNativeAlarm" -> {
                    try {
                        val requestCode = call.argument<Int>("requestCode") ?: 0
                        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
                        val pending = PendingIntent.getBroadcast(
                            this, requestCode, Intent(this, AlarmReceiver::class.java),
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        alarmManager.cancel(pending)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Mendaftarkan file suara ke MediaStore (bukan lewat FileProvider), supaya
     * URI-nya bisa dibaca sistem secara resmi tanpa masalah izin lintas-proses.
     *
     * PENTING: fungsi ini IDEMPOTEN. Kalau entri dengan [displayName] yang
     * sama sudah ada, URI yang sama langsung dikembalikan TANPA menghapus
     * dan membuat ulang. Ini disengaja: channel notifikasi Android yang
     * sudah dibuat terkunci ke satu URI suara tertentu selamanya, jadi kalau
     * fungsi ini menghapus lalu membuat entri baru setiap aplikasi dibuka
     * (seperti versi sebelumnya), channel yang sudah ada jadi menunjuk ke
     * entri yang sudah terhapus -> muncul sebagai "Nada dering tak dikenal".
     * [displayName] harus unik per versi suara (disertakan channelVersion
     * dari sisi Dart), supaya suara BARU tetap dapat entri baru yang bersih.
     */
    private fun registerSoundInMediaStore(sourcePath: String, displayName: String): String {
        val resolver = applicationContext.contentResolver
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        resolver.query(
            collection,
            arrayOf(MediaStore.Audio.Media._ID),
            "${MediaStore.Audio.Media.DISPLAY_NAME} = ?",
            arrayOf(displayName),
            null
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(idColumn)
                return ContentUris.withAppendedId(collection, id).toString()
            }
        }

        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_ALARM, 1)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_NOTIFICATIONS)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
        }

        val itemUri = resolver.insert(collection, values)
            ?: throw Exception("Gagal membuat entri MediaStore untuk suara")

        resolver.openOutputStream(itemUri)?.use { out ->
            File(sourcePath).inputStream().use { input -> input.copyTo(out) }
        } ?: throw Exception("Gagal menulis file suara ke MediaStore")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val doneValues = ContentValues()
            doneValues.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(itemUri, doneValues, null, null)
        }

        return itemUri.toString()
    }
}
