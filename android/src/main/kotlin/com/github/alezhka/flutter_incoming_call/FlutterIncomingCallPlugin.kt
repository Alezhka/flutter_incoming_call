package com.github.alezhka.flutter_incoming_call

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
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
    val TAG = "FlutterIncomingCallPlug"
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
          android.util.Log.e(TAG, "onMethodCall displayIncomingCall: Not Configured")
          result.error("not_configured", "Not configured", null)
          return
        }

        val callData = FactoryModels.parseCallData(call)
        android.util.Log.d(TAG, "onMethodCall displayIncomingCall callData: $callData")

        context?.let {
          Log.d(TAG, "onMethodCall displayIncomingCall")
          notificationCall?.showCallNotification(callData, config!!)
          it.sendBroadcast(CallBroadcastReceiver.startedIntent(it, callData))
        } ?: run {
          android.util.Log.e(TAG, "onMethodCall displayIncomingCall: context is null")
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
    notificationCall = CallNotification(binding.activity)
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
    notificationCall = CallNotification(binding.activity)
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
