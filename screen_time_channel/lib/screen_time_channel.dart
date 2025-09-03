import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ✅ These imports now point to the files you moved into the plugin's lib folder.
import 'app_usage_stat.dart';
import 'installed_app.dart';
import 'screen_time_service.dart';

class ScreenTimeChannel implements ScreenTimeService {
  static const _channel = MethodChannel('com.screenpledge.app/screentime');

  // --- PASTE THE ENTIRE CONTENTS of your old AndroidScreenTimeService class here ---
  // The code inside the methods does not need to change.
  
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
      final int millis = await _channel.invokeMethod<int>(
            'getUsageForApps',
            {'packageNames': packageNames},
          ) ?? 0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for apps: '${e.message}'.");
      return Duration.zero;
    }
  }

  @override
  Future<Duration> getTotalDeviceUsage() async {
    try {
      final int millis = await _channel.invokeMethod<int>('getTotalDeviceUsage') ?? 0;
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
          ) ?? 0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get counted device usage: '${e.message}'.");
      return Duration.zero;
    }
  }

  @override
  Future<Map<DateTime, Duration>> getWeeklyDeviceScreenTime() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getWeeklyDeviceScreenTime');
      if (result == null) return const {};
      final parsed = <DateTime, Duration>{};
      for (final entry in result.entries) {
        final keyStr = entry.key as String;
        final valueMs = entry.value as int;
        final day = DateTime.parse(keyStr);
        parsed[DateTime(day.year, day.month, day.day)] = Duration(milliseconds: valueMs);
      }
      return parsed;
    } on PlatformException catch (e) {
      debugPrint("Failed to get weekly device screen time: '${e.message}'.");
      return const {};
    }
  }

  @override
  Future<Map<DateTime, Duration>> getUsageForDateRange(DateTime start, DateTime end) async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getUsageForDateRange', {
        'startTime': start.millisecondsSinceEpoch,
        'endTime': end.millisecondsSinceEpoch,
      });
      if (result == null) return const {};
      final usageMap = <DateTime, Duration>{};
      for (final entry in result.entries) {
        final keyStr = entry.key as String;
        final valueMs = entry.value as int;
        final day = DateTime.parse(keyStr);
        usageMap[DateTime(day.year, day.month, day.day)] = Duration(milliseconds: valueMs);
      }
      return usageMap;
    } on PlatformException catch (e) {
      debugPrint("Failed to get usage for date range: '${e.message}'.");
      return const {};
    }
  }

  @override
  Future<List<AppUsageStat>> getDailyUsageBreakdown() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getDailyUsageBreakdown');
      if (result == null) return [];
      return result.map((appMap) {
        final map = Map<String, dynamic>.from(appMap);
        return AppUsageStat(
          app: InstalledApp(
            name: map['name'] ?? 'Unknown App',
            packageName: map['packageName'] ?? '',
            icon: map['icon'] as Uint8List,
          ),
          usage: Duration(milliseconds: map['usageMillis'] ?? 0),
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get daily usage breakdown: '${e.message}'.");
      return [];
    }
  }

  @override
  Future<List<Duration>> getScreenTimeForLastSixDays() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getScreenTimeForLastSixDays');
      if (result == null) return [];
      return result.map((millis) => Duration(milliseconds: millis as int)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get screen time for last six days: '${e.message}'.");
      return [];
    }
  }

  @override
  Future<Duration> getTotalUsageForDate(DateTime date) async {
    try {
      final int millis = await _channel.invokeMethod<int>(
        'getTotalUsageForDate',
        {'date': date.millisecondsSinceEpoch},
      ) ?? 0;
      return Duration(milliseconds: millis);
    } on PlatformException catch (e) {
      debugPrint("Failed to get total usage for date: '${e.message}'.");
      return Duration.zero;
    }
  }
}