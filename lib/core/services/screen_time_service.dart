import 'package:screenpledge/core/domain/entities/installed_app.dart';

/// Cross‑platform contract for screen‑time functionality.
///
/// IMPORTANT:
/// - Keep this interface minimal and **deduplicated**. Every method listed here
///   must have exactly one declaration (the build error you saw was caused by
///   accidentally declaring `getUsageTopApps` twice).
/// - Names map 1:1 to the platform channel methods used by the Android
///   implementation so we can reason about them easily.
///
/// Terminology:
/// - "Per‑app usage" (summing target packages; overlaps allowed) is different
///   from "device total" (union of all foreground intervals gated by screen‑on
///   + unlocked). Digital Wellbeing uses the latter when it shows total time.
///
abstract class ScreenTimeService {
  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Opens the system's Usage Access settings screen so the user can grant
  /// `android.permission.PACKAGE_USAGE_STATS` on Android.
  Future<void> requestPermission();

  /// Returns true if usage access permission is currently granted.
  Future<bool> isPermissionGranted();

  // ---------------------------------------------------------------------------
  // App catalog helpers
  // ---------------------------------------------------------------------------

  /// All user‑launchable applications with icons (used for pickers / chips).
  Future<List<InstalledApp>> getInstalledApps();

  /// Top used apps list for UX (used to pre‑select in pickers).
  Future<List<InstalledApp>> getUsageTopApps();

  // ---------------------------------------------------------------------------
  // Usage (today, since local midnight)
  // ---------------------------------------------------------------------------

  /// Sums the foreground time for the provided packages since **local midnight**.
  /// This is an **overlap‑allowed** sum (i.e., split‑screen can double count),
  /// which is fine for “select apps / groups” goal mode.
  Future<Duration> getUsageForApps(List<String> packageNames);

  /// Today’s **device total** since local midnight, using the **Digital
  /// Wellbeing semantics** (union of foreground intervals gated by:
  /// screen‑interactive ∩ device‑unlocked).
  Future<Duration> getTotalDeviceUsage();

  /// Today’s **counted time** based on the goal type:
  /// - `goalType = 'custom_group'` → union of included packages (gated).
  /// - `goalType = 'total_time'`    → union of all packages except exempt (gated).
  ///
  /// The native side expects these exact strings; we keep it stringly‑typed
  /// at the boundary to avoid pulling UI enums into `core/services/`.
  Future<Duration> getCountedDeviceUsage({
    required String goalType,
    List<String> trackedPackages,
    List<String> exemptPackages,
  });

  // ---------------------------------------------------------------------------
  // Historical
  // ---------------------------------------------------------------------------

  /// Seven day, **device total** bars (Digital Wellbeing style), keyed by
  /// local‑midnight DateTime for each day.
  ///
  /// Returned map will contain 7 entries (Sun→Sat or rolling 7 days depending
  /// on how you render it). Values are **gated union** totals.
  Future<Map<DateTime, Duration>> getWeeklyDeviceScreenTime();

  /// Legacy: bucketed per‑day totals using `queryUsageStats`. Kept for any
  /// places still depending on it, but **prefer** `getWeeklyDeviceScreenTime`
  /// for charts that must match Settings.
  Future<Map<DateTime, Duration>> getUsageForDateRange(DateTime start, DateTime end);
}
