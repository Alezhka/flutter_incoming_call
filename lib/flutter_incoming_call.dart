import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show describeEnum;

import 'models.dart';
import 'config.dart';

export 'models.dart';
export 'config.dart';

enum HandleType {
  generic,
  number,
  email,
}

class FlutterIncomingCall {

  static const MethodChannel _channel = const MethodChannel('flutter_incoming_call');
  static const EventChannel _eventChannel = const EventChannel('flutter_incoming_call_events');

  static Stream<BaseCallEvent> get onEvent =>
      _eventChannel.receiveBroadcastStream().map(_toCallEvent);

  static Future<void> configure({
    required String appName,
    int duration = 30000,
    ConfigAndroid? android,
    ConfigIOS? ios,
  }) async {
    await _channel.invokeMethod('configure', <String, dynamic> {
      'appName': appName,
      'duration': duration,
      if(Platform.isAndroid && android != null) ...android.toMap(),
      if(Platform.isIOS && ios != null) ...ios.toMap(),
    });
  }

  static Future<void> displayIncomingCallAdvanced(String uuid, String name,
      { String? avatar = null,
        String? handle = null,
        HandleType? handleType = null,
        bool hasVideo = false,
        bool supportsDTMF = false,
        bool supportsHolding = false,
        bool supportsGrouping = false,
        bool supportsUngrouping = false
      })
  async {
    await _channel.invokeMethod('displayIncomingCall', <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'avatar': avatar,
      'handle': handle,
      'handleType': handleType == null ? null : describeEnum(handleType),
      'hasVideo': hasVideo,
      'supportsDTMF': supportsDTMF,
      'supportsHolding': supportsHolding,
      'supportsGrouping': supportsGrouping,
      'supportsUngrouping': supportsUngrouping,
    });
  }

  static Future<void> displayIncomingCall(String uuid, String name, String avatar, String handle, HandleType handleType, bool hasVideo) async {
    await _channel.invokeMethod('displayIncomingCall', <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'avatar': avatar,
      'handle': handle,
      'handleType': describeEnum(handleType),
      'hasVideo': hasVideo,
      'supportsDTMF': true,
      'supportsHolding': true,
      'supportsGrouping': true,
      'supportsUngrouping': true,
    });
  }

  static Future<void> endCall(String uuid) async {
    await _channel.invokeMethod('endCall', <String, dynamic>{
      'uuid': uuid,
    });
  }

  static Future<void> endAllCalls() async {
    await _channel.invokeMethod('endAllCalls');
  }

  static BaseCallEvent _toCallEvent(dynamic data) {
    if (data is Map) {
      final event = data['event'];
      final body = Map<String, dynamic>.from(data['body']);

      switch(event) {
        case kEventCallAccept:
          return CallEvent.fromMap(CallAction.accept, body);
        case kEventCallDecline:
          return CallEvent.fromMap(CallAction.decline, body);
        case kEventCallMissed:
          return CallEvent.fromMap(CallAction.missed, body);
        case kEventCallStarted:
          return CallEvent.fromMap(CallAction.started, body);
        case kEventToggleHold:
          return HoldEvent.fromMap(body);
        case kEventToggleMute:
          return MuteEvent.fromMap(body);
        case kEventToggleDmtf:
          return DmtfEvent.fromMap(body);
        case kEventToggleAudioSession:
          return AudioSessionEvent.fromMap(body);
      }
    }
    throw Exception('Undefined event!');
  }


}