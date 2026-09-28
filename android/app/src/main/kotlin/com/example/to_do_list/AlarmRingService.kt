package com.example.to_do_list

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.io.File

/**
 * Foreground service yang benar-benar memutar suara alarm memakai
 * MediaPlayer di jalur audio ALARM (bukan notifikasi), sama seperti
 * aplikasi Jam bawaan HP. Berjalan walau layar mati/terkunci.
 */
class AlarmRingService : Service() {
    companion object {
        const val ACTION_STOP = "com.example.to_do_list.ACTION_STOP_ALARM"
        private const val CHANNEL_ID = "native_alarm_ring_channel"
        private const val NOTIF_ID = 991199
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopRinging()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra("title") ?: "Waktunya!"
        val soundPath = intent?.getStringExtra("soundPath")

        startForegroundNotification(title)
        acquireWakeLock()
        playSound(soundPath)
        launchAlarmActivity(title)

        return START_NOT_STICKY
    }

    private fun startForegroundNotification(title: String) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Alarm Sedang Berbunyi", NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(this, AlarmRingService::class.java).apply { action = ACTION_STOP }
        val stopPending = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Cara resmi Android untuk menampilkan layar alarm di atas layar kunci
        // dari latar belakang: lewat fullScreenIntent pada notifikasi.
        val fullScreenPending = PendingIntent.getActivity(
            this, 1,
            Intent(this, AlarmRingActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("title", title)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText("Alarm sedang berbunyi")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setFullScreenIntent(fullScreenPending, true)
            .addAction(0, "Matikan", stopPending)
            .build()

        startForeground(NOTIF_ID, notification)
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "todolist:alarm_ring"
        )
        wakeLock?.setReferenceCounted(false)
        wakeLock?.acquire(10 * 60 * 1000L) // maksimal 10 menit, jaga-jaga kalau lupa dimatikan
    }

    private fun playSound(soundPath: String?) {
        try {
            mediaPlayer = MediaPlayer().apply {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setAudioAttributes(attributes)

                if (soundPath != null && File(soundPath).exists()) {
                    setDataSource(soundPath)
                } else {
                    val fallback = RingtoneManager.getActualDefaultRingtoneUri(
                        this@AlarmRingService, RingtoneManager.TYPE_ALARM
                    ) ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    setDataSource(this@AlarmRingService, fallback)
                }

                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            // Tidak fatal: layar tetap menyala dan getaran tetap jalan
            // walau pemutaran suara gagal karena satu dan lain hal.
        }
    }

    private fun launchAlarmActivity(title: String) {
        // Percobaan tambahan langsung membuka layar alarm. Di Android 10+
        // ini bisa ditolak sistem kalau aplikasi di latar belakang; tidak
        // masalah, karena fullScreenIntent di notifikasi sudah jadi jalur
        // utamanya, dan suara tetap berbunyi lewat service ini.
        try {
            val activityIntent = Intent(this, AlarmRingActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("title", title)
            }
            startActivity(activityIntent)
        } catch (_: Exception) {
        }
    }

    private fun stopRinging() {
        mediaPlayer?.let {
            try { it.stop() } catch (_: Exception) { }
            it.release()
        }
        mediaPlayer = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        stopRinging()
        super.onDestroy()
    }
}
