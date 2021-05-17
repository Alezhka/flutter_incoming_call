import 'package:flutter/foundation.dart';

class ConfigAndroid {

  final String channelId;
  final String channelName;
  final String channelDescription;
  final String ringtonePath;
  final bool vibration;

  ConfigAndroid({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.ringtonePath = "default",
    this.vibration = false,
  });

  Map<String, dynamic> toMap() => {
    'channelId': channelId,
    'channelName': channelName,
    'channelDescription': channelDescription,
    'ringtonePath': ringtonePath,
    'vibration': vibration,
  };
}

class ConfigIOS {

  final bool supportsVideo;
  final bool includesCallsInRecents;
  final int maximumCallGroups;
  final int maximumCallsPerCallGroup;
  final String iconName;
  final String? ringtonePath;

  ConfigIOS({
    required this.supportsVideo,
    required this.includesCallsInRecents,
    required this.maximumCallGroups,
    required this.maximumCallsPerCallGroup,
    required this.iconName,
    this.ringtonePath,
  });

  Map<String, dynamic> toMap() => {
    'supportsVideo': supportsVideo,
    'includesCallsInRecents': includesCallsInRecents,
    'maximumCallGroups': maximumCallGroups,
    'maximumCallsPerCallGroup': maximumCallsPerCallGroup,
    'ringtonePath': ringtonePath,
    'iconName': iconName,
  };
}