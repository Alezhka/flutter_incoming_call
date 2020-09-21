import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show describeEnum, required;

import 'models.dart';

export 'models.dart';

enum HandleType {
  generic,
  number,
  email,
}

class FlutterIncomingCall {

  static const MethodChannel _channel = const MethodChannel('flutter_incoming_call');
  static const EventChannel _eventChannel = const EventChannel('flutter_incoming_call_events');

  static Stream<CallEvent> get onEvent =>
      _eventChannel.receiveBroadcastStream().map(_toCallEvent);

  static Future<void> configure({
    @required String appName,
    @required bool includesCallsInRecents, // IOS
    @required String channelId, // Android
    @required String channelName, // Android
    @required String channelDescription, // Android
  }) async {
    await _channel.invokeMethod('configure', <String, dynamic> {
      'appName': appName,
      'includesCallsInRecents': includesCallsInRecents,
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
    });
  }

  static Future<void> displayIncomingCall(String uuid, String name, String avatar, String handle, HandleType handleType, bool hasVideo, {
    bool vibration,
    bool ringtone,
    String ringtonePath,
    int duration,
  }) async {
    assert(uuid != null);
    assert(name != null);

    if(Platform.isIOS){
      endAllCalls();
    }

    await _channel.invokeMethod('displayIncomingCall', <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'avatar': avatar,
      'handle': handle,
      'handleType': describeEnum(handleType),
      'hasVideo': hasVideo,
      'vibration': vibration,
      'ringtone': ringtone,
      'ringtonePath': ringtonePath,
      'duration': duration,
    });
  }

  static Future<void> endCall(String uuid) async {
    assert(uuid != null);
    await _channel.invokeMethod('endCall', <String, dynamic>{
      'uuid': uuid,
    });
  }

  static Future<void> endAllCalls() async {
    await _channel.invokeMethod('endAllCalls');
  }

  static CallEvent _toCallEvent(dynamic data) {
    if (data is Map) {
      final event = data['event'];
      final body = new Map<String, dynamic>.from(data['body']);
      return CallEvent.fromMap(event, body);
    }
    return null;
  }


}