package com.example.masarifi

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object NotificationScheduler {
    const val TASK_CHANNEL_ID = "masarifi_tasks"
    const val DEBT_CHANNEL_ID = "masarifi_debts"

    private val scheduledIds = mutableSetOf<Int>()

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    TASK_CHANNEL_ID,
                    "المهام والمواعيد",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "تنبيهات المهام والمواعيد"
                },
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    DEBT_CHANNEL_ID,
                    "الديون",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "تذكير بمواعيد سداد الديون"
                },
            )
        }
    }

    fun showNotification(
        context: Context,
        id: Int,
        channelId: String,
        title: String,
        body: String,
    ) {
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    fun schedule(
        context: Context,
        id: Int,
        channelId: String,
        title: String,
        body: String,
        triggerAtMillis: Long,
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, NotificationReceiver::class.java).apply {
            putExtra("notification_id", id)
            putExtra("title", title)
            putExtra("body", body)
            putExtra("channel_id", channelId)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pending,
        )
        scheduledIds.add(id)
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (id in scheduledIds) {
            val intent = Intent(context, NotificationReceiver::class.java)
            val pending = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            alarmManager.cancel(pending)
        }
        scheduledIds.clear()
        NotificationManagerCompat.from(context).cancelAll()
    }
}
