package com.ibrahemalhuossien.focusflow

import android.Manifest
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Flutter draws the animated intro. Remove Android 12's exit overlay
        // immediately after the first Flutter frame instead of hiding its start.
        if (Build.VERSION.SDK_INT >= 31) {
            splashScreen.setOnExitAnimationListener { it.remove() }
        }
    }
    private var permissionResult: MethodChannel.Result? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "focus_flow/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            if (permissionResult != null) result.success(false)
                            else {
                                permissionResult = result
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 401)
                            }
                        } else result.success(getSystemService(NotificationManager::class.java).areNotificationsEnabled())
                    }
                    "playSound" -> {
                        try {
                            val uri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
                            android.media.RingtoneManager.getRingtone(this, uri)?.play()
                            result.success(null)
                        } catch (e: Exception) { result.error("sound", e.message, null) }
                    }
                    "clear" -> {
                        try {
                            ReminderReceiver.clearAll(this)
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("clear_failed", "Could not clear local reminders", null)
                        }
                    }
                    "schedule" -> {
                        try {
                            val args = call.arguments as Map<*, *>
                            val prefs = getSharedPreferences("focus_flow_reminders", MODE_PRIVATE)
                            val committed = prefs.edit()
                                .putBoolean("daily", args["daily"] == true)
                                .putBoolean("streak", args["streak"] == true)
                                .putInt("hour", (args["hour"] as Number).toInt())
                                .putInt("minute", (args["minute"] as Number).toInt())
                                .putString("lastFocusDate", args["lastFocusDate"] as? String)
                                .commit()
                            if (!committed) throw IllegalStateException("Could not persist reminders")
                            ReminderReceiver.scheduleAll(this)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("schedule_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 401) {
            permissionResult?.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
            permissionResult = null
        }
    }
}
