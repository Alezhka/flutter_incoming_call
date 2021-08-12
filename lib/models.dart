


const kEventCallStarted = "call_started";
const kEventCallAccept = "call_accept";
const kEventCallDecline = "call_decline";
const kEventCallMissed = "call_missed";
const kEventToggleHold = "toggle_hold";
const kEventToggleMute = "toggle_mute";
const kEventToggleDmtf = "toggle_dmtf";
const kEventToggleAudioSession = "toggle_audiosession";

enum CallAction { started, accept, decline, missed }

abstract class BaseCallEvent {
}

class CallEvent extends BaseCallEvent {

  final CallAction action;
  final String uuid;
  final String name;
  final String handleType;
  final String avatar;

  CallEvent({
    required this.action, 
    required this.uuid, 
    required this.name, 
    required this.handleType, 
    required this.avatar
  });

  factory CallEvent.fromMap(CallAction action, Map<String, dynamic> body) {
    return CallEvent(
        action: action,
        uuid: body['uuid'],
        name: body['name'],
        handleType: body['handleType'],
        avatar: body['avatar'],
    );
  }

  @override
  String toString() =>
      'CallEvent { uuid: $uuid, name: $name, handleType: $handleType, avatar: $avatar }';
}

class HoldEvent extends BaseCallEvent {

  final String uuid;
  final bool hold;

  HoldEvent({
    required this.uuid, 
    required this.hold
  });

  factory HoldEvent.fromMap(Map<String, dynamic> body) {
    return HoldEvent(
      uuid: body['uuid'],
      hold: body['hold'],
    );
  }

  @override
  String toString() =>
      'HoldEvent { uuid: $uuid, hold: $hold }';

}

class MuteEvent extends BaseCallEvent {

  final String uuid;
  final bool mute;

  MuteEvent({
    required this.uuid, 
    required this.mute
  });

  factory MuteEvent.fromMap(Map<String, dynamic> body) {
    return MuteEvent(
      uuid: body['uuid'],
      mute: body['muted'],
    );
  }

  @override
  String toString() =>
      'MuteEvent { uuid: $uuid, mute: $mute }';

}


class DmtfEvent extends BaseCallEvent {

  final String uuid;
  final String digits;

  DmtfEvent({
    required this.uuid, 
    required this.digits
  });

  factory DmtfEvent.fromMap(Map<String, dynamic> body) {
    return DmtfEvent(
      uuid: body['uuid'],
      digits: body['digits'],
    );
  }

  @override
  String toString() =>
      'DmtfEvent { uuid: $uuid, digits: $digits }';

}

class AudioSessionEvent extends BaseCallEvent {

  final bool activate;

  AudioSessionEvent({
    required this.activate
  });

  factory AudioSessionEvent.fromMap(Map<String, dynamic> body) {
    return AudioSessionEvent(
      activate: body['activate'],
    );
  }

  @override
  String toString() =>
      'AudioSessionEvent { activate: $activate }';

}