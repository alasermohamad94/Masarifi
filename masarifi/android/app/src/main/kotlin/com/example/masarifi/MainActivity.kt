package com.example.masarifi

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "masarifi/notifications"
    private val requestCodeNotifications = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationScheduler.createChannels(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "cancelAll" -> {
                    NotificationScheduler.cancelAll(this)
                    result.success(null)
                }
                "schedule" -> {
                    val id = call.argument<Int>("id") ?: 0
                    val channelId = call.argument<String>("channelId")
                        ?: NotificationScheduler.TASK_CHANNEL_ID
                    val title = call.argument<String>("title") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val triggerAt = call.argument<Long>("triggerAt") ?: 0L
                    NotificationScheduler.schedule(
                        this,
                        id,
                        channelId,
                        title,
                        body,
                        triggerAt,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    requestCodeNotifications,
                )
            }
        }
    }
}
