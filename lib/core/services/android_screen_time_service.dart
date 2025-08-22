// lib/core/services/android_screen_time_service.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// The concrete Android implementation of the [ScreenTimeService].
class AndroidScreenTimeService implements ScreenTimeService {
  static const _channel = MethodChannel('com.screenpledge.app/screentime');

  @override
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to open usage settings: '${e.message}'.");
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission status: '${e.message}'.");
      return false;
    }
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledApps');
      if (result == null) return [];

      return result.map((appMap) {
        final map = Map<String, dynamic>.from(appMap);
        return InstalledApp(
          name: map['name'] ?? 'Unknown App',
          packageName: map['packageName'] ?? '',
          icon: map['icon'] as Uint8List,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get installed apps: '${e.message}'.");
      return [];
    }
  }

  @override
  Future<List<InstalledApp>> getUsageTopApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getUsageTopApps');
      if (result == null) return [];

      return result.map((appMap) {
        final map = Map<String, dynamic>.from(appMap);
        return InstalledApp(
          name: map['name'] ?? 'Unknown App',
          packageName: map['packageName'] ?? '',
          icon: map['icon'] as Uint8List,
        );
      }).toList();
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint('Cannot get usage stats: Permission denied.');
      } else {
        debugPrint("Failed to get usage top apps: '${e.message}'.");
      }
      return [];
    }
  }

  /// ✅ ADDED: Implementation for fetching usage for a specific list of apps.
  @override
  Future<Duration> getUsageForApps(List<String> packageNames) async {
    // If the list is empty, we don't need to make a native call.
    if (packageNames.isEmpty) return Duration.zero;
    try {
      // Pass the list of package names as an argument to the native method.
      final int milliseconds = await _channel.invokeMethod<int>(
        'getUsageForApps',
        {'packageNames': packageNames},
      ) ?? 0;
      return Duration(milliseconds: milliseconds);
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for apps: '${e.message}'.");
      return Duration.zero; // Return zero on failure.
    }
  }

  /// ✅ ADDED: Implementation for fetching total device usage.
  @override
  Future<Duration> getTotalDeviceUsage() async {
    try {
      final int milliseconds = await _channel.invokeMethod<int>('getTotalDeviceUsage') ?? 0;
      return Duration(milliseconds: milliseconds);
    } on PlatformException catch (e) {
      debugPrint("Failed to get total device usage: '${e.message}'.");
      return Duration.zero;
    }
  }
}