package com.example.to_do_list

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Layar alarm native (BUKAN layar Flutter), sengaja dibuat sangat
 * sederhana supaya bisa langsung tampil di atas layar kunci tanpa
 * menunggu Flutter engine siap. Hanya berisi judul tugas dan tombol
 * "Matikan Alarm".
 */
class AlarmRingActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }

        val title = intent.getStringExtra("title") ?: "Waktunya!"

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#1B1F2A"))
            setPadding(64, 64, 64, 64)
        }

        val icon = TextView(this).apply {
            text = "\u23F0"
            textSize = 64f
            gravity = Gravity.CENTER
        }
        val titleView = TextView(this).apply {
            text = title
            textSize = 22f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 80)
        }
        val stopButton = Button(this).apply {
            text = "Matikan Alarm"
            textSize = 18f
            setPadding(48, 32, 48, 32)
            setOnClickListener {
                val stopIntent = Intent(this@AlarmRingActivity, AlarmRingService::class.java)
                stopIntent.action = AlarmRingService.ACTION_STOP
                startService(stopIntent)
                finish()
            }
        }

        layout.addView(icon)
        layout.addView(titleView)
        layout.addView(stopButton)
        setContentView(layout)
    }
}
