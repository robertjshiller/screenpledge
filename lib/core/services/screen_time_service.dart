// Original comments are retained.
import 'package:screenpledge/core/domain/entities/app_usage_stat.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';

/// Cross‑platform contract for screen‑time functionality.
///
/// IMPORTANT:
/// - Keep this interface minimal and **deduplicated**. Every method listed here
///   must have exactly one declaration.
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
  Future<Duration> getUsageForApps(List<String> packageNames);

  /// Today’s **device total** since local midnight, using the **Digital
  /// Wellbeing semantics**.
  Future<Duration> getTotalDeviceUsage();

  /// Today’s **counted time** based on the goal type.
  Future<Duration> getCountedDeviceUsage({
    required String goalType,
    List<String> trackedPackages,
    List<String> exemptPackages,
  });

  // ---------------------------------------------------------------------------
  // Historical & Breakdown
  // ---------------------------------------------------------------------------

  /// Seven day, **device total** bars (Digital Wellbeing style), keyed by
  /// local‑midnight DateTime for each day.
  Future<Map<DateTime, Duration>> getWeeklyDeviceScreenTime();

  /// Legacy: bucketed per‑day totals using `queryUsageStats`.
  Future<Map<DateTime, Duration>> getUsageForDateRange(DateTime start, DateTime end);

  /// ✅ ADDED: Fetches a detailed breakdown of per-app usage for today,
  /// sorted by duration in descending order.
  Future<List<AppUsageStat>> getDailyUsageBreakdown();

  /// Fetches the total screen time for each of the last six days, excluding today.
  Future<List<Duration>> getScreenTimeForLastSixDays();

  // ✅ NEW: A dedicated method to get the final, total device usage for a
  // specific historical date. This is essential for our background data
  // submission task, which needs to report "yesterday's" final total.
  Future<Duration> getTotalUsageForDate(DateTime date);
}