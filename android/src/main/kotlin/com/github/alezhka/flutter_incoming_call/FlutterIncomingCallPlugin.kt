package com.github.alezhka.flutter_incoming_call

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterIncomingCallPlugin */
class FlutterIncomingCallPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  
  companion object {
    var activity: Activity? = null
    val eventHandler = EventStreamHandler()
    var ringtonePlayer: CallPlayer? = null
    var config: PluginConfig? = null
  }
  
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var events: EventChannel
  private var context: Context? = null
  private var notificationCall: CallNotification? = null
  private var isConfigured = false
  private var callPrefs: CallPreferences? = null
  
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_incoming_call")
    events = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_incoming_call_events")
    channel.setMethodCallHandler(this)
    events.setStreamHandler(eventHandler)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when(call.method) {
      "configure" -> {
        config = FactoryModels.parseConfig(call)
        callPrefs?.config = config

        if(ringtonePlayer == null) {
          ringtonePlayer = CallPlayer(context!!, config!!)
        } else {
          ringtonePlayer!!.config = config!!
        }
        isConfigured = true

        result.success(null)
      }
      "displayIncomingCall" -> {
        if(!isConfigured) {
          result.error("not_configured", "Not configured", null)
          return
        }
        
        val callData = FactoryModels.parseCallData(call)

        context?.let {
          if(Utils.isDeviceScreenLocked(it)) {
            activity?.startActivity(IncomingCallActivity.start(callData))
          } else {
            notificationCall?.showCallNotification(callData, config!!)
          }
          it.sendBroadcast(CallBroadcastReceiver.startedIntent(it, callData))
        }

        result.success(null)
      }
      "endCall" -> {
        val uuid = call.argument<String>("uuid")
        IncomingCallActivity.dismissIncoming(uuid)
        notificationCall?.clearNotification(uuid.hashCode())
        ringtonePlayer?.stop()

        result.success(null)
      }
      "endAllCalls" -> {
        IncomingCallActivity.dismissIncoming(null)
        notificationCall?.clearAllNotifications()
        ringtonePlayer?.stop()

        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    context = binding.activity
    notificationCall = CallNotification(context!!)
    callPrefs = CallPreferences(binding.activity)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    context = null
    notificationCall = null
    callPrefs = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    context = binding.activity
    callPrefs = CallPreferences(binding.activity)
    notificationCall = CallNotification(context!!)
  }

  override fun onDetachedFromActivity() {
    activity = null
    context = null
    notificationCall = null
  }


  class EventStreamHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
      eventSink = sink
    }

    fun send(event: String, body: Map<String, Any?>) {
      val data = mapOf(
              "event" to event,
              "body" to body
      )
      Handler(Looper.getMainLooper()).post {
        eventSink?.success(data)
      }
    }

    override fun onCancel(p0: Any?) {
      eventSink = null
    }
  }
}
