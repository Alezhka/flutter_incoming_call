package com.github.alezhka.flutter_incoming_call

import android.os.Parcelable
import io.flutter.plugin.common.MethodCall
import kotlinx.android.parcel.Parcelize
import java.util.*

data class PluginConfig(
        val appName: String,
        val channelId: String,
        val channelName: String,
        val channelDescription: String
)

@Parcelize
data class CallData(
        val uuid: String,
        val handle: String,
        val name: String,
        val avatar: String?,
        val handleType: String,
        val hasVideo: Boolean,
        val notificationId: Int,
        val vibration: Boolean,
        val ringtone: Boolean,
        val ringtonePath: String,
        val duration: Long
) : Parcelable


object FactoryModels {

    fun parseCallData(call: MethodCall): CallData {
        val uuid = call.argument<String>("uuid") ?: ""
        val handle = call.argument<String>("handle") ?: ""
        val name = call.argument<String>("name") ?: ""
        val handleType = call.argument<String>("handleType") ?: ""
        val avatar = call.argument<String>("avatar")
        val hasVideo = call.argument<Boolean>("hasVideo") ?: false
        val notificationId = call.argument<Int>("notificationId") ?: Random().nextInt(10000)
        val vibration = call.argument<Boolean>("vibration") ?: false
        val ringtone = call.argument<Boolean>("ringtone") ?: false
        val ringtonePath = call.argument<String>("ringtonePath") ?: "default"
        val duration = call.argument<Long>("duration") ?: 30000L
        return CallData(uuid, handle, name, avatar, handleType, hasVideo, notificationId, vibration, ringtone, ringtonePath, duration)
    }

    fun parseConfig(call: MethodCall): PluginConfig {
        val appName = call.argument<String>("appName") ?: ""
        val channelId = call.argument<String>("channelId") ?: ""
        val channelName = call.argument<String>("channelName") ?: ""
        val channelDescription = call.argument<String>("channelDescription") ?: ""
        return PluginConfig(appName, channelId, channelName, channelDescription)
    }
}
