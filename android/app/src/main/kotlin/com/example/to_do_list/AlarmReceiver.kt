package com.example.to_do_list

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Diterima saat AlarmManager membangunkan alarm (bahkan dari kondisi HP
 * tidur dalam/Doze), lalu meneruskan ke AlarmRingService yang benar-benar
 * memutar suaranya. Tidak pakai flutter_local_notifications sama sekali di
 * sini, supaya tidak tunduk ke batasan notifikasi biasa.
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AlarmRingService::class.java).apply {
            putExtra("title", intent.getStringExtra("title"))
            putExtra("soundPath", intent.getStringExtra("soundPath"))
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
