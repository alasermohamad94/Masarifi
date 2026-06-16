package com.example.masarifi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("notification_id", 0)
        val title = intent.getStringExtra("title") ?: "مصاريفي"
        val body = intent.getStringExtra("body") ?: ""
        val channelId = intent.getStringExtra("channel_id")
            ?: NotificationScheduler.TASK_CHANNEL_ID

        NotificationScheduler.showNotification(context, id, channelId, title, body)
    }
}
