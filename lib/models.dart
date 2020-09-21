
class CallEvent {

  static const kEventCallStarted = "call_started";
  static const kEventCallAccept = "call_accept";
  static const kEventCallDecline = "call_decline";
  static const kEventCallMissed = "call_missed";

  final String event;
  final String uuid;
  final String name;
  final String handle;
  final String avatar;

  CallEvent({this.event, this.uuid, this.name, this.handle, this.avatar});

  factory CallEvent.fromMap(String event, Map<String, dynamic> body) {
    return CallEvent(
        event: event,
        uuid: body['uuid'],
        name: body['name'],
        handle: body['handle'],
        avatar: body['avatar'],
    );
  }

  @override
  String toString() =>
      'CallEvent { event: $event, uuid: $uuid, name: $name, handle: $handle, avatar: $avatar }';
}
