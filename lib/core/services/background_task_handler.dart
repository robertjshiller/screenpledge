import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:screenpledge/core/data/repositories/cache_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:screenpledge/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

// ✅ UPDATED IMPORTS: We now import from our new plugin package.
import 'package:screen_time_channel/screen_time_channel.dart';
import 'package:screen_time_channel/screen_time_service.dart';


// --- Task Definitions ---
const dailyDataSubmissionTask = "com.screenpledge.app.dailyDataSubmissionTask";
const warningNotificationTask = "com.screenpledge.app.warningNotificationTask";

/// A helper class for scheduling tasks from the main app UI, primarily for debugging.
class BackgroundTaskScheduler {
  static void triggerWarningTaskNow() {
    Workmanager().registerOneOffTask(
      "manualWarningTrigger-${DateTime.now().millisecondsSinceEpoch}",
      warningNotificationTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
    print("🔵 Manual Trigger: Requested immediate run of warningNotificationTask.");
  }

  // ✅ ADD THIS NEW STATIC METHOD
  /// Manually triggers the daily data submission task to run immediately.
  /// This is intended for debugging purposes.
  static void triggerSubmissionTaskNow() {
    Workmanager().registerOneOffTask(
      "manualSubmissionTrigger-${DateTime.now().millisecondsSinceEpoch}", // Unique name
      dailyDataSubmissionTask, // The name of the task we want to run
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: Duration.zero,
      constraints: Constraints(networkType: NetworkType.connected), // This task needs the network
    );
    print("🔵 Manual Trigger: Requested immediate run of dailyDataSubmissionTask.");
  }

}

// --- Top-Level Dispatcher ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      await _initializeSupabaseForBackground();
      await NotificationService.initialize();
    } catch (e) {
      print('🔴 FATAL ERROR during background initialization: $e');
      return false;
    }

    try {
      switch (task) {
        case dailyDataSubmissionTask:
          final handler = DailyDataSubmissionHandler();
          return await handler.submitDailyData();
        case warningNotificationTask:
          final handler = WarningNotificationHandler();
          return await handler.runWarningChecks();
        default:
          return true;
      }
    } catch (e) {
      print('🔴 FATAL ERROR in callbackDispatcher: $e');
      return false;
    }
  });
}

Future<void> _initializeSupabaseForBackground() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

class DailyDataSubmissionHandler {
  static const _lastSubmissionDateKey = 'last_submission_date';

  Future<bool> submitDailyData() async {
    const logPrefix = "✅ BackgroundTask (Submit):";
    try {
      print("$logPrefix Task started.");
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        print("$logPrefix No user logged in. Exiting.");
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      // ✅ CHANGED: Instantiate the service from the plugin.
      final screenTimeService = ScreenTimeChannel();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDateString = DateFormat('yyyy-MM-dd').format(yesterday);
      final lastSubmission = prefs.getString(_lastSubmissionDateKey);

      if (lastSubmission == yesterdayDateString) {
        print("$logPrefix Already submitted for $yesterdayDateString. Exiting.");
        return true;
      }

      print("$logPrefix Fetching final usage for yesterday ($yesterdayDateString)...");
      final finalUsage = await screenTimeService.getTotalUsageForDate(yesterday);
      print("$logPrefix Final usage was ${finalUsage.inMinutes} minutes. Submitting to server...");

      await Supabase.instance.client.functions.invoke('process-daily-result',
        body: {
          'date': yesterdayDateString,
          'timezone': now.timeZoneName,
          'final_usage_seconds': finalUsage.inSeconds,
        },
      );
      await prefs.setString(_lastSubmissionDateKey, yesterdayDateString);
      print("$logPrefix SUCCESS: Submission complete.");
      return true;
    } catch (e) {
      print("🔴 BackgroundTask (Submit): FAILED. Error: $e");
      return false;
    }
  }
}

class WarningNotificationHandler {
  static const _lastNotifiedThresholdKey = 'last_notified_threshold';
  static const _lastCheckedDateKey = 'last_checked_date';

  Future<bool> runWarningChecks() async {
    const logPrefix = "✅ BackgroundTask (Warning):";
    try {
      print("$logPrefix Task started in background isolate.");

      print("$logPrefix Initializing services...");
      final ICacheRepository cache = CacheRepositoryImpl();
      // ✅ CHANGED: Instantiate the service from the plugin.
      final ScreenTimeService screenTimeService = ScreenTimeChannel();
      final prefs = await SharedPreferences.getInstance();
      print("$logPrefix Services initialized.");

      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastCheckedDate = prefs.getString(_lastCheckedDateKey);
      print("$logPrefix Today is $todayString. Last checked date was $lastCheckedDate.");
      if (lastCheckedDate != todayString) {
        print("$logPrefix New day detected. Resetting notification threshold.");
        await prefs.setDouble(_lastNotifiedThresholdKey, 0.0);
        await prefs.setString(_lastCheckedDateKey, todayString);
      }

      print("$logPrefix Fetching active goal from cache...");
      final goal = await cache.getActiveGoal();
      if (goal == null) {
        print("$logPrefix No active goal found in cache. Task will exit.");
        return true;
      }
      print("$logPrefix Goal found: ${goal.timeLimit.inMinutes} minutes.");

      print("$logPrefix Attempting to fetch current device usage via MethodChannel...");
      final currentUsage = await screenTimeService.getTotalDeviceUsage();
      print("$logPrefix SUCCESS: Fetched current usage: ${currentUsage.inMinutes} minutes.");

      final goalLimitSeconds = goal.timeLimit.inSeconds;
      final currentUsageSeconds = currentUsage.inSeconds;
      final lastNotifiedThreshold = prefs.getDouble(_lastNotifiedThresholdKey) ?? 0.0;
      print("$logPrefix Current usage: $currentUsageSeconds/${goalLimitSeconds}s. Last notified at: ${lastNotifiedThreshold * 100}%.");

      final thresholds = {0.50: 1, 0.75: 2, 0.90: 3, 1.0: 4};
      double newThresholdToStore = lastNotifiedThreshold;

      for (final entry in thresholds.entries) {
        final thresholdPercent = entry.key;
        if (currentUsageSeconds >= (goalLimitSeconds * thresholdPercent) && lastNotifiedThreshold < thresholdPercent) {
          print("$logPrefix CROSSED THRESHOLD: ${thresholdPercent * 100}%. Sending notification.");
          if (thresholdPercent == 0.50) { await NotificationService.show50PercentWarning(); }
          if (thresholdPercent == 0.75) { await NotificationService.show75PercentWarning(); }
          if (thresholdPercent == 0.90) { await NotificationService.show90PercentWarning(); }
          if (thresholdPercent == 1.00) { await NotificationService.showFailureConfirmation(); }
          newThresholdToStore = thresholdPercent;
        }
      }

      if (newThresholdToStore > lastNotifiedThreshold) {
        await prefs.setDouble(_lastNotifiedThresholdKey, newThresholdToStore);
        print("$logPrefix Updated last notified threshold to ${newThresholdToStore * 100}%.");
      }

      if (newThresholdToStore >= 1.0) {
        print("$logPrefix Goal failed. No further checks will be scheduled for today.");
        return true;
      }

      double nextMilestonePercent = 0.5;
      if (newThresholdToStore >= 0.90) { nextMilestonePercent = 1.0; }
      else if (newThresholdToStore >= 0.75) { nextMilestonePercent = 0.90; }
      else if (newThresholdToStore >= 0.50) { nextMilestonePercent = 0.75; }

      final targetUsageSeconds = goalLimitSeconds * nextMilestonePercent;
      final secondsToNextMilestone = targetUsageSeconds - currentUsageSeconds;

      Duration nextCheckDelay;
      if (secondsToNextMilestone <= 0) {
        nextCheckDelay = const Duration(minutes: 1);
      } else {
        nextCheckDelay = Duration(seconds: secondsToNextMilestone.toInt());
      }

      const minDelay = Duration(minutes: 1);
      const maxDelay = Duration(minutes: 30);
      if (nextCheckDelay < minDelay) { nextCheckDelay = minDelay; }
      if (nextCheckDelay > maxDelay) { nextCheckDelay = maxDelay; }
      
      print("$logPrefix Calculated next check delay: ${nextCheckDelay.inMinutes} minutes.");

      Workmanager().registerOneOffTask(
        "warningNotificationTask-${DateTime.now().millisecondsSinceEpoch}",
        warningNotificationTask,
        initialDelay: nextCheckDelay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
      print("$logPrefix SUCCESS: Next check scheduled. Task finished.");

      return true;
    } catch (e) {
      print("🔴 BackgroundTask (Warning): FAILED. Error: $e");
      return false;
    }
  }
}