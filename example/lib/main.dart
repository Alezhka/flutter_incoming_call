import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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

  CallEvent _lastEvent;

  void _incomingCall() {
    FlutterIncomingCall.displayIncomingCall(uuid.v4(), 'Daenerys Targaryen', 'https://scontent.fhel6-1.fna.fbcdn.net/v/t1.0-9/62009611_2487704877929752_6506356917743386624_n.jpg?_nc_cat=102&_nc_sid=09cbfe&_nc_ohc=cIgJjOYlVj0AX_J7pnl&_nc_ht=scontent.fhel6-1.fna&oh=ef2b213b74bd6999cd74e3d5de235cf4&oe=5F6E3331', 'example_incoming_call', HandleType.generic, true,
      vibration: true,
      ringtone: true,
    );
  }

  void _endCurrentCall() {
    if(_lastEvent != null) {
      FlutterIncomingCall.endCall(_lastEvent.uuid);
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
      includesCallsInRecents: false,
      channelId: 'calls',
      channelName: 'Calls channel name',
      channelDescription: 'Calls channel description',
    );
    FlutterIncomingCall.onEvent.listen((event) {
      setState(() { _lastEvent = event; });
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
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FlatButton(
              child: Text('Incoming call now'),
              onPressed: _incomingCall,
            ),
            SizedBox(height: 16),
            FlatButton(
              child: Text('Incoming call delay 5 sec'),
              onPressed: () => Future.delayed(Duration(seconds: 5), _incomingCall),
            ),
            SizedBox(height: 16),
            FlatButton(
              child: Text('End current call'),
              onPressed: _endCurrentCall,
            ),
            SizedBox(height: 16),
            FlatButton(
              child: Text('End all calls'),
              onPressed: _endAllCalls,
            ),
            SizedBox(height: 16),
            Text(
              _lastEvent != null ? _lastEvent.toString() : 'Not event',
              style: TextStyle(
                fontSize: 16
              ),
            )
          ],
        ),
      ),
    );
  }
}
