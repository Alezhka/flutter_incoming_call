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
  final bool avSessionSetCategory;
  final bool avSessionSetMode;
  final bool avSessionSetPreferredSampleRate;
  final bool avSessionSetPreferredIOBufferDuration;
  final bool avSessionSetActive;

  ConfigIOS({
    required this.supportsVideo,
    required this.includesCallsInRecents,
    required this.maximumCallGroups,
    required this.maximumCallsPerCallGroup,
    required this.iconName,
    this.ringtonePath,
    this.avSessionSetActive = true,
    this.avSessionSetCategory = true,
    this.avSessionSetMode = true,
    this.avSessionSetPreferredIOBufferDuration = true,
    this.avSessionSetPreferredSampleRate = true
  });

  Map<String, dynamic> toMap() => {
    'supportsVideo': supportsVideo,
    'includesCallsInRecents': includesCallsInRecents,
    'maximumCallGroups': maximumCallGroups,
    'maximumCallsPerCallGroup': maximumCallsPerCallGroup,
    'ringtonePath': ringtonePath,
    'iconName': iconName,
    'avSessionSetActive': avSessionSetActive,
    'avSessionSetCategory': avSessionSetCategory,
    'avSessionSetMode': avSessionSetMode,
    'avSessionSetPreferredIOBufferDuration': avSessionSetPreferredIOBufferDuration,
    'avSessionSetPreferredSampleRate': avSessionSetPreferredSampleRate
  };
}