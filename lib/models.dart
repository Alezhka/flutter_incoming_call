


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
  final String handle;
  final String avatar;

  CallEvent({this.action, this.uuid, this.name, this.handle, this.avatar});

  factory CallEvent.fromMap(CallAction action, Map<String, dynamic> body) {
    return CallEvent(
        action: action,
        uuid: body['uuid'],
        name: body['name'],
        handle: body['handle'],
        avatar: body['avatar'],
    );
  }

  @override
  String toString() =>
      'CallEvent { uuid: $uuid, name: $name, handle: $handle, avatar: $avatar }';
}

class HoldEvent extends BaseCallEvent {

  final String uuid;
  final bool hold;

  HoldEvent({this.uuid, this.hold});

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

  MuteEvent({this.uuid, this.mute});

  factory MuteEvent.fromMap(Map<String, dynamic> body) {
    return MuteEvent(
      uuid: body['uuid'],
      mute: body['mute'],
    );
  }

  @override
  String toString() =>
      'MuteEvent { uuid: $uuid, mute: $mute }';

}


class DmtfEvent extends BaseCallEvent {

  final String uuid;
  final String digits;

  DmtfEvent({this.uuid, this.digits});

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

  AudioSessionEvent({this.activate});

  factory AudioSessionEvent.fromMap(Map<String, dynamic> body) {
    return AudioSessionEvent(
      activate: body['activate'],
    );
  }

  @override
  String toString() =>
      'AudioSessionEvent { activate: $activate }';

}