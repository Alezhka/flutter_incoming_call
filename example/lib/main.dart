import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_incoming_call/flutter_incoming_call.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  var uuid = Uuid();

  BaseCallEvent? _lastEvent;
  CallEvent? _lastCallEvent;
  HoldEvent? _lastHoldEvent;
  MuteEvent? _lastMuteEvent;
  DmtfEvent? _lastDmtfEvent;
  AudioSessionEvent? _lastAudioSessionEvent;

  void _incomingCall() {
    final uid = uuid.v4();
    final name = 'Daenerys Targaryen';
    final avatar = 'https://scontent.fhel6-1.fna.fbcdn.net/v/t1.0-9/62009611_2487704877929752_6506356917743386624_n.jpg?_nc_cat=102&_nc_sid=09cbfe&_nc_ohc=cIgJjOYlVj0AX_J7pnl&_nc_ht=scontent.fhel6-1.fna&oh=ef2b213b74bd6999cd74e3d5de235cf4&oe=5F6E3331';
    final handle = 'example_incoming_call';
    final type = HandleType.generic;
    final isVideo = true;
    FlutterIncomingCall.displayIncomingCall(uid, name, avatar, handle, type, isVideo);
  }

  void _endCurrentCall() {
    if(_lastEvent != null) {
      FlutterIncomingCall.endCall(_lastCallEvent!.uuid);
    }
  }

  void _endAllCalls() {
    FlutterIncomingCall.endAllCalls();
  }

  @override
  void initState() {
    super.initState();
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
    );
    FlutterIncomingCall.onEvent.listen((event) {
      setState(() { _lastEvent = event; });
      if(event is CallEvent) {
        setState(() { _lastCallEvent = event; });
      } else if(event is HoldEvent) {
        setState(() { _lastHoldEvent = event; });
      } else if(event is MuteEvent) {
        setState(() { _lastMuteEvent = event; });
      } else if(event is DmtfEvent) {
        setState(() { _lastDmtfEvent = event; });
      } else if(event is AudioSessionEvent) {
        setState(() { _lastAudioSessionEvent = event; });
      }
    });
  }

  @override
  void dispose() {
    _endAllCalls();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                child: Text('Incoming call now'),
                onPressed: _incomingCall,
              ),
              SizedBox(height: 16),
              TextButton(
                child: Text('Incoming call delay 5 sec'),
                onPressed: () => Future.delayed(Duration(seconds: 5), _incomingCall),
              ),
              SizedBox(height: 16),
              TextButton(
                child: Text('End current call'),
                onPressed: _endCurrentCall,
              ),
              SizedBox(height: 16),
              TextButton(
                child: Text('End all calls'),
                onPressed: _endAllCalls,
              ),
              SizedBox(height: 16),
              Text(
                'Last event:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _lastEvent != null ? _lastEvent.toString() : 'Not event',
                style: TextStyle(
                    fontSize: 16
                ),
              ),
              if(_lastCallEvent != null) ...[
                Text(
                  'Last call event:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastCallEvent.toString(),
                  style: TextStyle(
                      fontSize: 16
                  ),
                )
              ],
              if(_lastHoldEvent != null) ...[
                Text(
                  'Last hold event:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastHoldEvent.toString(),
                  style: TextStyle(
                      fontSize: 16
                  ),
                )
              ],
              if(_lastMuteEvent != null) ...[
                Text(
                  'Last mute event:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastMuteEvent.toString(),
                  style: TextStyle(
                      fontSize: 16
                  ),
                )
              ],
              if(_lastDmtfEvent != null) ...[
                Text(
                  'Last dmtf event:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastDmtfEvent.toString(),
                  style: TextStyle(
                      fontSize: 16
                  ),
                )
              ],
              if(_lastAudioSessionEvent != null) ...[
                Text(
                  'Last audio session event:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastAudioSessionEvent.toString(),
                  style: TextStyle(
                      fontSize: 16
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
