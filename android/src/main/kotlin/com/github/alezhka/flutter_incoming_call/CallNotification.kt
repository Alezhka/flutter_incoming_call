package com.github.alezhka.flutter_incoming_call

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat


class CallNotification(private val context: Context) {

    companion object {

        private const val notificationChannel = "NotificationChannel"

        private val highPriority: Int
            get() = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                NotificationManager.IMPORTANCE_HIGH
            } else {
                Notification.PRIORITY_MAX
            }
    }

    fun showCallNotification(callData: CallData, config: PluginConfig) {
        if(FlutterIncomingCallPlugin.ringtonePlayer == null) {
            FlutterIncomingCallPlugin.ringtonePlayer = CallPlayer(context, config)
        }

        FlutterIncomingCallPlugin.ringtonePlayer?.let {
            if(!it.isPlaying()) it.play(callData)
        }

        val notificationID = callData.notificationId
        val declineIntent = CallBroadcastReceiver.declineIntent(context, callData)
        val acceptIntent = CallBroadcastReceiver.acceptIntent(context, callData)
        val declinePi = PendingIntent.getBroadcast(context, 0, declineIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        val acceptPi = PendingIntent.getBroadcast(context, 0, acceptIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        val soundUri: Uri = Uri.parse("android.resource://${context.packageName}/${R.raw.nosound}")
        val notification: Notification = NotificationCompat.Builder(context, config.channelId)
                .setAutoCancel(true)
                .setDefaults(0)
                .setCategory(Notification.CATEGORY_CALL)
                .setOngoing(true)
                .setTimeoutAfter(config.duration)
                .setOnlyAlertOnce(true)
                .setFullScreenIntent(getCallerActivityPendingIntent(notificationID, callData), true)
                .setContentIntent(getCallerActivityPendingIntent(notificationID, callData))
                .setSmallIcon(R.drawable.ic_call_black_24dp)
                .setPriority(highPriority)
                .setContentTitle(callData.name)
                .setSound(soundUri)
                .setContentText(callData.handle)
                .addAction(0, context.getString(R.string.action_accept), acceptPi)
                .addAction(0, context.getString(R.string.action_decline), declinePi)
                .build()
        val notificationManager = notificationManager()
        createCallNotificationChannel(notificationManager, config)
        notificationManager.notify(notificationID, notification)
    }

    fun showMissCallNotification(callData: CallData) {
        val notificationID = callData.notificationId
        val missedCallSound: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val contentIntent = getCallerActivityPendingIntent(notificationID, callData)
        val notification: Notification = NotificationCompat.Builder(context, notificationChannel)
                .setContentTitle(callData.name)
                .setContentText(callData.handle)
                .setSmallIcon(R.drawable.ic_phone_missed_black_24dp)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setSound(missedCallSound)
                .setContentIntent(contentIntent)
                .build()
        val notificationManager = notificationManager()
        createNotificationChannel(notificationManager, missedCallSound)
        notificationManager.notify(notificationID, notification)
    }

    fun clearNotification(notificationID: Int) {
        val notificationManager = notificationManager()
        notificationManager.cancel(notificationID)
    }

    fun clearAllNotifications() {
        val manager = notificationManager()
        manager.cancelAll()
    }

    private fun createCallNotificationChannel(manager: NotificationManager, config: PluginConfig) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            /*
            val soundUri: Uri = Uri.parse("android.resource://${context.packageName}/${R.raw.nosound}")
            val attribution = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_UNKNOWN)
                    .build()
             */
            val channel = NotificationChannel(config.channelId, config.channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                description = config.channelDescription
                // setSound(soundUri, attribution)
                // vibrationPattern = longArrayOf(0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000)
                // enableVibration(config.vibration)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun getCallerActivityPendingIntent(notificationID: Int, callData: CallData): PendingIntent? {
        val intent = IncomingCallActivity.start(callData)
        return PendingIntent.getActivity(context, notificationID, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun createNotificationChannel(manager: NotificationManager, soundUri: Uri?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val attributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_UNKNOWN)
                    .build()
            val channel = NotificationChannel(notificationChannel, "missed call", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Call Notifications"
                setSound(soundUri, attributes)
                vibrationPattern = longArrayOf(0, 1000)
                enableVibration(true)
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun notificationManager(): NotificationManager {
        return context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }
    
}