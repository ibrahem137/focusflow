package com.ibrahemalhuossien.focusflow

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Calendar-based one-shot alarms are recalculated after delivery, reboot and time changes. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val kind = intent.getStringExtra("kind")
        val prefs = context.getSharedPreferences("focus_flow_reminders", Context.MODE_PRIVATE)
        if (kind != null && prefs.getBoolean(kind, false)) {
            val yesterday = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -1) }
            val previousDate = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(yesterday.time)
            val shouldShow = kind == "daily" || prefs.getString("lastFocusDate", null) == previousDate
            if (shouldShow) {
                val manager = context.getSystemService(NotificationManager::class.java)
                if (Build.VERSION.SDK_INT >= 26) {
                    manager.createNotificationChannel(NotificationChannel("focus_reminders", "Focus reminders", NotificationManager.IMPORTANCE_DEFAULT))
                }
                if (manager.areNotificationsEnabled()) {
                    val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                    val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, "focus_reminders") else Notification.Builder(context)
                    val notification = builder.setSmallIcon(R.drawable.ic_notification)
                        .setContentTitle(if (kind == "daily") "Time for a little focus" else "Keep your focus streak growing")
                        .setContentText("Protect a few minutes for meaningful work. Your garden is waiting.")
                        .setAutoCancel(true).setContentIntent(open).build()
                    try { manager.notify(if (kind == "daily") 101 else 102, notification) } catch (_: SecurityException) { }
                }
            }
        }
        scheduleAll(context)
    }
    companion object {
        fun clearAll(context: Context) {
            var failure: Exception? = null
            try {
                if (!context.getSharedPreferences("focus_flow_reminders", Context.MODE_PRIVATE).edit().clear().commit()) {
                    throw IllegalStateException("Could not clear reminder preferences")
                }
            } catch (e: Exception) { failure = e }
            for ((id, kind) in listOf(101 to "daily", 102 to "streak")) {
                try {
                    val intent = Intent(context, ReminderReceiver::class.java).putExtra("kind", kind)
                    val pending = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE)
                    if (pending != null) {
                        context.getSystemService(AlarmManager::class.java).cancel(pending)
                        pending.cancel()
                    }
                } catch (e: Exception) { failure = e }
            }
            try { context.getSystemService(NotificationManager::class.java).cancelAll() }
            catch (e: Exception) { failure = e }
            failure?.let { throw it }
        }

        fun scheduleAll(context: Context) {
            val prefs = context.getSharedPreferences("focus_flow_reminders", Context.MODE_PRIVATE)
            val alarms = context.getSystemService(AlarmManager::class.java)
            for ((id, kind) in listOf(101 to "daily", 102 to "streak")) {
                val intent = Intent(context, ReminderReceiver::class.java).putExtra("kind", kind)
                val pending = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                alarms.cancel(pending)
                if (!prefs.getBoolean(kind, false)) {
                    context.getSystemService(NotificationManager::class.java).cancel(id)
                    continue
                }
                val now = Calendar.getInstance()
                val next = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, if (kind == "daily") prefs.getInt("hour", 19) else 20)
                    set(Calendar.MINUTE, if (kind == "daily") prefs.getInt("minute", 0) else 30)
                    set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                    if (!after(now)) add(Calendar.DAY_OF_YEAR, 1)
                }
                // Reminders do not require exact-alarm special access.
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
            }
        }
    }
}
