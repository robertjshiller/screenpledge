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

  @override
  Future<Duration> getUsageForApps(List<String> packageNames) async {
    if (packageNames.isEmpty) return Duration.zero;
    try {
      final int milliseconds = await _channel.invokeMethod<int>(
        'getUsageForApps',
        {'packageNames': packageNames},
      ) ?? 0;
      return Duration(milliseconds: milliseconds);
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for apps: '${e.message}'.");
      return Duration.zero;
    }
  }

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

  /// ✅ ADDED: Implementation for fetching historical usage data.
  @override
  Future<Map<DateTime, Duration>> getUsageForDateRange(DateTime start, DateTime end) async {
    try {
      debugPrint('[AndroidScreenTimeService] Invoking getUsageForDateRange from $start to $end');
      // The native side returns a Map<String, int> (date string to milliseconds).
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getUsageForDateRange', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
      });

      if (result == null) return {};

      // We parse the raw map from the native side into our strongly-typed Dart map.
      final usageMap = result.map((key, value) {
        return MapEntry(
          DateTime.parse(key as String),
          Duration(milliseconds: value as int),
        );
      });
      debugPrint('[AndroidScreenTimeService] Received ${usageMap.length} days of historical data.');
      return usageMap;
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for date range: '${e.message}'.");
      return {}; // Return an empty map on failure.
    }
  }
}