// lib/core/services/screen_time_service.dart

import 'package:screenpledge/core/domain/entities/installed_app.dart';

/// An abstract class defining the contract for a platform-specific screen time service.
/// This contract defines the capabilities our app needs for interacting with native screen time APIs.
abstract class ScreenTimeService {
  /// Opens the system's Usage Access Settings screen for the user.
  Future<void> requestPermission();

  /// Checks if the screen time permission has already been granted.
  Future<bool> isPermissionGranted();

  /// Fetches a list of all user-installed, launchable applications.
  Future<List<InstalledApp>> getInstalledApps();

  /// Fetches a list of the most used apps based on screen time.
  Future<List<InstalledApp>> getUsageTopApps();

  /// Fetches the total combined usage time for a specific list of apps since midnight.
  Future<Duration> getUsageForApps(List<String> packageNames);

  /// Fetches the total screen-on time for all apps on the device since midnight.
  Future<Duration> getTotalDeviceUsage();

  /// ✅ ADDED: Fetches historical usage data for a given date range.
  ///
  /// Returns a map where the key is the [DateTime] (normalized to midnight)
  /// and the value is the total usage [Duration] for that day.
  Future<Map<DateTime, Duration>> getUsageForDateRange(DateTime start, DateTime end);
}