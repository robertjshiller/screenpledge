import 'package:flutter_test/flutter_test.dart';
import 'package:screen_time_channel/screen_time_channel.dart';
import 'package:screen_time_channel/screen_time_channel_platform_interface.dart';
import 'package:screen_time_channel/screen_time_channel_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockScreenTimeChannelPlatform
    with MockPlatformInterfaceMixin
    implements ScreenTimeChannelPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ScreenTimeChannelPlatform initialPlatform = ScreenTimeChannelPlatform.instance;

  test('$MethodChannelScreenTimeChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelScreenTimeChannel>());
  });

  test('getPlatformVersion', () async {
    ScreenTimeChannel screenTimeChannelPlugin = ScreenTimeChannel();
    MockScreenTimeChannelPlatform fakePlatform = MockScreenTimeChannelPlatform();
    ScreenTimeChannelPlatform.instance = fakePlatform;

    expect(await screenTimeChannelPlugin.getPlatformVersion(), '42');
  });
}
