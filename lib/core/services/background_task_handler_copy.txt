// lib/core/services/background_task_handler.dart

// ✅ NEW: Import dart:ui to access the DartPluginRegistrant.
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:screenpledge/core/data/repositories/cache_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:screenpledge/core/services/android_screen_time_service.dart';
import 'package:screenpledge/core/services/notification_service.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

// --- Task Definitions ---
const dailyDataSubmissionTask = "com.screenpledge.app.dailyDataSubmissionTask";
const warningNotificationTask = "com.screenpledge.app.warningNotificationTask";

// --- Top-Level Dispatcher ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  // This is the entry point for all background tasks.
  Workmanager().executeTask((task, inputData) async {
    // ✅ THE DEFINITIVE FIX: This initialization block runs EVERY time a background
    // task is started. It prepares the clean background isolate with all the
    // necessary services before our logic runs.

    // 1. Ensure basic Flutter bindings are ready.
    WidgetsFlutterBinding.ensureInitialized();
    // 2. This is the key to fixing the MissingPluginException. It finds and
    //    registers all plugins (including our custom MethodChannel) for this isolate.
    DartPluginRegistrant.ensureInitialized();
    // 3. Initialize Supabase and dotenv for this isolate.
    await _initializeSupabaseForBackground();
    // 4. Initialize the NotificationService for this isolate.
    await NotificationService.initialize();

    // Now that the environment is ready, we can safely delegate to the handlers.
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
      print('Unhandled error in callbackDispatcher: $e');
      return false;
    }
  });
}

/// A shared, top-level function to initialize Supabase in the background.
Future<void> _initializeSupabaseForBackground() async {
  await dotenv.load(fileName: ".env");
  // Check if an instance already exists to prevent re-initialization errors.
  if (Supabase.instance.client.auth.currentUser == null) {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}

// =============================================================================
// HANDLER 1: Daily Data Submission
// =============================================================================

class DailyDataSubmissionHandler {
  static const _lastSubmissionDateKey = 'last_submission_date';

  Future<bool> submitDailyData() async {
    try {
      // Initialization is now handled globally in the dispatcher.
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return true;

      final prefs = await SharedPreferences.getInstance();
      final screenTimeService = AndroidScreenTimeService();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDateString = DateFormat('yyyy-MM-dd').format(yesterday);
      final lastSubmission = prefs.getString(_lastSubmissionDateKey);

      if (lastSubmission == yesterdayDateString) return true;

      final finalUsage = await screenTimeService.getTotalUsageForDate(yesterday);
      final timezone = now.timeZoneName;

      await Supabase.instance.client.functions.invoke('process-daily-result',
        body: {
          'date': yesterdayDateString,
          'timezone': timezone,
          'final_usage_seconds': finalUsage.inSeconds,
        },
      );
      await prefs.setString(_lastSubmissionDateKey, yesterdayDateString);
      return true;
    } catch (e) {
      print('BackgroundTask (Submit): Failed. Error: $e');
      return false;
    }
  }
}

// =============================================================================
// HANDLER 2: Warning Notifications
// =============================================================================

class WarningNotificationHandler {
  static const _lastNotifiedThresholdKey = 'last_notified_threshold';
  static const _lastCheckedDateKey = 'last_checked_date';

  Future<bool> runWarningChecks() async {
    try {
      // Initialization is now handled globally.
      final ICacheRepository cache = CacheRepositoryImpl();
      final ScreenTimeService screenTimeService = AndroidScreenTimeService();
      final prefs = await SharedPreferences.getInstance();

      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastCheckedDate = prefs.getString(_lastCheckedDateKey);
      if (lastCheckedDate != todayString) {
        await prefs.setDouble(_lastNotifiedThresholdKey, 0.0);
        await prefs.setString(_lastCheckedDateKey, todayString);
      }

      final goal = await cache.getActiveGoal();
      if (goal == null) return true;

      final goalLimitSeconds = goal.timeLimit.inSeconds;
      // This call will now succeed because the MethodChannel is registered.
      final currentUsage = await screenTimeService.getTotalDeviceUsage();
      final currentUsageSeconds = currentUsage.inSeconds;
      final lastNotifiedThreshold = prefs.getDouble(_lastNotifiedThresholdKey) ?? 0.0;

      final thresholds = {0.50: 1, 0.75: 2, 0.90: 3, 1.0: 4};
      double newThresholdToStore = lastNotifiedThreshold;

      for (final entry in thresholds.entries) {
        final thresholdPercent = entry.key;
        if (currentUsageSeconds >= (goalLimitSeconds * thresholdPercent) && lastNotifiedThreshold < thresholdPercent) {
          if (thresholdPercent == 0.50) await NotificationService.show50PercentWarning();
          if (thresholdPercent == 0.75) await NotificationService.show75PercentWarning();
          if (thresholdPercent == 0.90) await NotificationService.show90PercentWarning();
          if (thresholdPercent == 1.00) await NotificationService.showFailureConfirmation();
          newThresholdToStore = thresholdPercent;
        }
      }

      if (newThresholdToStore > lastNotifiedThreshold) {
        await prefs.setDouble(_lastNotifiedThresholdKey, newThresholdToStore);
      }

      if (newThresholdToStore >= 1.0) return true;

      double nextMilestonePercent = 0.5;
      if (newThresholdToStore >= 0.90) nextMilestonePercent = 1.0;
      else if (newThresholdToStore >= 0.75) nextMilestonePercent = 0.90;
      else if (newThresholdToStore >= 0.50) nextMilestonePercent = 0.75;

      final targetUsageSeconds = goalLimitSeconds * nextMilestonePercent;
      final secondsToNextMilestone = targetUsageSeconds - currentUsageSeconds;

      Duration nextCheckDelay;
      if (secondsToNextMilestone <= 0) {
        nextCheckDelay = const Duration(minutes: 5);
      } else {
        nextCheckDelay = Duration(seconds: secondsToNextMilestone.toInt());
      }

      const minDelay = Duration(minutes: 5);
      const maxDelay = Duration(minutes: 30);
      if (nextCheckDelay < minDelay) nextCheckDelay = minDelay;
      if (nextCheckDelay > maxDelay) nextCheckDelay = maxDelay;

      // This call will now succeed because Workmanager was initialized in the dispatcher.
      Workmanager().registerOneOffTask(
        "warningNotificationTask-${DateTime.now().millisecondsSinceEpoch}",
        warningNotificationTask,
        initialDelay: nextCheckDelay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
      print('BackgroundTask (Warning): Next check scheduled in ${nextCheckDelay.inMinutes} minutes.');

      return true;
    } catch (e) {
      print('BackgroundTask (Warning): Failed. Error: $e');
      return false;
    }
  }
}