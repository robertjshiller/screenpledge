
// ✅ FIXED: This import is now USED by the methods in this file.
import 'package:screenpledge/core/domain/entities/installed_app.dart';

/// An abstract class defining the contract for a platform-specific screen time service.
// This contract defines the capabilities our app needs for interacting with native screen time APIs.
abstract class ScreenTimeService {
  /// Opens the system's Usage Access Settings screen for the user.
  Future<void> requestPermission();

  /// Checks if the screen time permission has already been granted.
  Future<bool> isPermissionGranted();

  /// Fetches a list of all user-installed, launchable applications.
  ///
  /// On Android, this queries the PackageManager.
  /// On iOS, this functionality is not supported and this method should return an empty list.
  Future<List<InstalledApp>> getInstalledApps();

  /// Fetches a list of the most used apps based on screen time.
  ///
  /// This provides the data for the "Suggested" or "Time Sinks" tab.
  /// It uses UsageStatsManager on Android and DeviceActivity on iOS.
  Future<List<InstalledApp>> getUsageTopApps();
}

// ✅ REMOVED: The old, duplicate definition of the InstalledApp class has been deleted.
// This resolves both the 'unused_import' and 'todo' diagnostic messages.