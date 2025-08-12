import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// The concrete Android implementation of the [ScreenTimeService].
class AndroidScreenTimeService implements ScreenTimeService {
  static const _channel = MethodChannel('com.screenpledge.app/screentime');

  // This method remains unchanged.
  @override
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch  (e) {
      debugPrint("Failed to open usage settings: '${e.message}'.");
    }
  }

  // This method remains unchanged.
  @override
  Future<bool> isPermissionGranted() async {
    try {
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission status: '${e.message}'.");
      return false;
    }
  }

  /// ✅ ADDED: Implementation for fetching all installed apps.
  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      // Call the native method. The result is a List of Maps.
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledApps');
      if (result == null) return [];

      // Map the raw list of maps into a list of our strongly-typed InstalledApp entities.
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
      return []; // Return an empty list on failure.
    }
  }

  /// ✅ ADDED: Implementation for fetching the top used apps.
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
      // Specifically handle the case where permission is denied.
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint('Cannot get usage stats: Permission denied.');
        // Optionally, re-throw a more specific exception type here.
      } else {
        debugPrint("Failed to get usage top apps: '${e.message}'.");
      }
      return [];
    }
  }
}