import 'dart:typed_data';

/// An abstract class defining the contract for a platform-specific screen time service.
// This contract defines the capabilities our app needs for interacting with native screen time APIs.
abstract class ScreenTimeService {
  /// ✅ CHANGED: This method now follows the "fire and forget" pattern.
  ///
  /// It opens the system's Usage Access Settings screen for the user, but it
  /// does NOT wait for a result. The Future completes as soon as the settings
  /// screen has been launched.
  /// The return type is now `Future<void>` to reflect this change.
  Future<void> requestPermission();

  /// Checks if the screen time permission has already been granted.
  ///
  /// This method performs a "verify by action" check on the native side and
  /// is the definitive way to determine the current permission status.
  Future<bool> isPermissionGranted();
}

/// A simple data class to hold information about an installed application.
class InstalledApp {
  final String name;
  final String bundleId;
  final Uint8List icon;

  InstalledApp({
    required this.name,
    required this.bundleId,
    required this.icon,
  });
}