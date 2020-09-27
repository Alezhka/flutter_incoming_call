package com.github.alezhka.flutter_incoming_call

import android.os.Parcelable
import io.flutter.plugin.common.MethodCall
import kotlinx.android.parcel.Parcelize

data class PluginConfig(
        val appName: String,
        val channelId: String,
        val channelName: String,
        val channelDescription: String,
        val vibration: Boolean,
        val ringtonePath: String?,
        val duration: Long
)

@Parcelize
data class CallData(
        val uuid: String,
        val handle: String,
        val name: String,
        val avatar: String?,
        val handleType: String,
        val hasVideo: Boolean
) : Parcelable {

    val notificationId: Int
        get() = uuid.hashCode()
}


object FactoryModels {

    fun parseCallData(call: MethodCall): CallData {
        val uuid = call.argument("uuid") as String? ?: ""
        val handle = call.argument("handle") as String? ?: ""
        val name = call.argument("name") as String? ?: ""
        val handleType = call.argument("handleType") as String? ?: ""
        val avatar = call.argument("avatar") as String?
        val hasVideo = call.argument("hasVideo") as Boolean? ?: false
        return CallData(uuid, handle, name, avatar, handleType, hasVideo)
    }

    fun parseConfig(call: MethodCall): PluginConfig {
        val appName = call.argument("appName") ?: ""
        val channelId = call.argument("channelId") as String? ?: ""
        val channelName = call.argument("channelName") as String? ?: ""
        val channelDescription = call.argument("channelDescription") as String? ?: ""
        val duration = (call.argument("duration") as Int? ?: 30000).toLong()
        val vibration = call.argument("vibration") as Boolean? ?: false
        val ringtonePath = call.argument("ringtonePath") as String?
        return PluginConfig(appName, channelId, channelName, channelDescription, vibration, ringtonePath, duration)
    }

    fun defaultConfig(): PluginConfig {
        val appName = ""
        val channelId = "call_channel_id"
        val channelName = "Call channel"
        val channelDescription = "Call channel"
        val duration = 30000L
        val vibration = false
        val ringtonePath = "default"
        return PluginConfig(appName, channelId, channelName, channelDescription, vibration, ringtonePath, duration)
    }
}
