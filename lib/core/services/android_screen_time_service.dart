import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// Android implementation that talks to the Kotlin side via a single platform
/// channel: `com.screenpledge.app/screentime`.
///
/// Channel methods implemented on the native side (MainActivity.kt):
/// - requestPermission
/// - isPermissionGranted
/// - getInstalledApps
/// - getUsageTopApps
/// - getUsageForApps
/// - getTotalDeviceUsage
/// - getWeeklyDeviceScreenTime
/// - getCountedDeviceUsage
/// - getUsageForDateRange   (legacy / compatibility)
class AndroidScreenTimeService implements ScreenTimeService {
  static const _channel = MethodChannel('com.screenpledge.app/screentime');

  // ===========================================================================
  // Permission
  // ===========================================================================

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

  // ===========================================================================
  // App catalog helpers
  // ===========================================================================

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

  // ===========================================================================
  // Usage (today)
  // ===========================================================================

  @override
  Future<Duration> getUsageForApps(List<String> packageNames) async {
    if (packageNames.isEmpty) return Duration.zero;
    try {
      final int millis = await _channel.invokeMethod<int>(
            'getUsageForApps',
            {'packageNames': packageNames},
          ) ??
          0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for apps: '${e.message}'.");
      return Duration.zero;
    }
  }

  @override
  Future<Duration> getTotalDeviceUsage() async {
    try {
      final int millis =
          await _channel.invokeMethod<int>('getTotalDeviceUsage') ?? 0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get total device usage: '${e.message}'.");
      return Duration.zero;
    }
  }

  @override
  Future<Duration> getCountedDeviceUsage({
    required String goalType,
    List<String> trackedPackages = const [],
    List<String> exemptPackages = const [],
  }) async {
    try {
      final int millis = await _channel.invokeMethod<int>(
            'getCountedDeviceUsage',
            <String, dynamic>{
              'goalType': goalType,
              'trackedPackages': trackedPackages,
              'exemptPackages': exemptPackages,
            },
          ) ??
          0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get counted device usage: '${e.message}'.");
      return Duration.zero;
    }
  }

  // ===========================================================================
  // Historical
  // ===========================================================================

  @override
  Future<Map<DateTime, Duration>> getWeeklyDeviceScreenTime() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getWeeklyDeviceScreenTime');

      if (result == null) return const {};

      // Native returns keys as "yyyy-MM-dd" (local), values as millis.
      final parsed = <DateTime, Duration>{};
      for (final entry in result.entries) {
        final keyStr = entry.key as String; // e.g., "2025-08-23"
        final valueMs = entry.value as int;
        final day = DateTime.parse(keyStr); // local midnight date
        parsed[DateTime(day.year, day.month, day.day)] =
            Duration(milliseconds: valueMs);
      }
      return parsed;
    } on PlatformException catch (e) {
      debugPrint("Failed to get weekly device screen time: '${e.message}'.");
      return const {};
    }
  }

  @override
  Future<Map<DateTime, Duration>> getUsageForDateRange(
      DateTime start, DateTime end) async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getUsageForDateRange', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
      });

      if (result == null) return const {};

      // Keys "yyyy-MM-dd" → DateTime(midnight local), value ms → Duration.
      final usageMap = <DateTime, Duration>{};
      for (final entry in result.entries) {
        final keyStr = entry.key as String;
        final valueMs = entry.value as int;
        final day = DateTime.parse(keyStr);
        usageMap[DateTime(day.year, day.month, day.day)] =
            Duration(milliseconds: valueMs);
      }
      return usageMap;
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for date range: '${e.message}'.");  
      return const {};
    }
  }
}
