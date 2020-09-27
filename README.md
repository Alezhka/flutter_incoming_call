# flutter_incoming_call

A Flutter plugin to show incoming call in your Flutter app!

## Usage

To use this plugin:

1. add to pubspec:
```
 flutter_incoming_call:
    git:
     url: https://github.com/Alezhka/flutter_incoming_call.git
```
 as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

2. configure plugin:
```
FlutterIncomingCall.configure(
    appName: 'example_incoming_call',
    duration: 30000,
    android: ConfigAndroid(
        vibration: true,
        ringtonePath: 'default',
        channelId: 'calls',
        channelName: 'Calls channel name',
        channelDescription: 'Calls channel description',
    ),
    ios: ConfigIOS(
        iconName: 'AppIcon40x40',
        ringtonePath: null,
        includesCallsInRecents: false,
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
    )
)
```
3. listen events:
```
FlutterIncomingCall.onEvent.listen((event) {
    if(event is CallEvent) { // Android | IOS
    } else if(event is HoldEvent) { // IOS
    } else if(event is MuteEvent) { // IOS
    } else if(event is DmtfEvent) { // IOS
    } else if(event is AudioSessionEvent) { // IOS
    }
});
```
4. call api:
```
FlutterIncomingCall.displayIncomingCall(String uid, String name, String avatar, String handle, String type, bool isVideo);
FlutterIncomingCall.endCall(String uuid);
FlutterIncomingCall.endAllCalls();
```

## Demo

ios | ios (Lockscreen) | Android  | Android (Lockscreen)
--- | --- | --- | ---
<img height="300" src="https://raw.githubusercontent.com/Alezhka/flutter_incoming_call/master/media/ios_incoming_call_2.PNG" style="max-width:100%;"> | <img height="300" src="https://raw.githubusercontent.com/Alezhka/flutter_incoming_call/master/media/ios_incoming_call_1.PNG" style="max-width:100%;"> | <img height="300" src="https://raw.githubusercontent.com/Alezhka/flutter_incoming_call/master/media/android_incoming_call_2.png" style="max-width:100%;"> | <img height="300" src="https://raw.githubusercontent.com/Alezhka/flutter_incoming_call/master/media/android_incoming_call_1.png" style="max-width:100%;">


## Example

Check out the example in the example project folder for a working example.
