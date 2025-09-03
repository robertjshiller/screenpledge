import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_time_channel_platform_interface.dart';

/// An implementation of [ScreenTimeChannelPlatform] that uses method channels.
class MethodChannelScreenTimeChannel extends ScreenTimeChannelPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('screen_time_channel');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
