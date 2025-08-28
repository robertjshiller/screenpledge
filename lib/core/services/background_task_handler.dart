//lib/core/services/background_task_handler.dart
// This import is necessary to use the `pragma` annotation for the top-level function.
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:screenpledge/core/services/android_screen_time_service.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class dedicated to handling the logic for background tasks.
/// This keeps the code organized and separate from the UI.
class BackgroundTaskHandler {
  // A key for storing the last submission date in shared preferences.
  static const _lastSubmissionDateKey = 'last_submission_date';

  /// This is the primary method for our daily data submission task.
  /// It's designed to be robust and handle the Reconciliation Protocol.
  Future<void> submitDailyData() async {
    // --- 1. Initialization ---
    // Since this code runs in a separate isolate, we must re-initialize
    // any services we need, like Supabase.
    await _initializeSupabase();

    // Check if there is a logged-in user. If not, we can't do anything.
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      print('BackgroundTask: No user logged in. Exiting.');
      return;
    }

    // --- 2. Determine Which Day to Process ---
    final prefs = await SharedPreferences.getInstance();
    final screenTimeService =
        AndroidScreenTimeService(); // Use the concrete implementation

    // Get today's date in the device's local timezone.
    final now = DateTime.now();
    // "Yesterday" is the completed day we need to process.
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDateString = DateFormat('yyyy-MM-dd').format(yesterday);

    // Check if we have already successfully submitted data for "yesterday".
    final lastSubmission = prefs.getString(_lastSubmissionDateKey);
    if (lastSubmission == yesterdayDateString) {
      print(
        'BackgroundTask: Data for $yesterdayDateString already submitted. Exiting.',
      );
      return;
    }

    // --- 3. Fetch Final Usage Data ---
    // Call our new native method to get the final, total device usage for yesterday.
    final Duration finalUsage;
    try {
      finalUsage = await screenTimeService.getTotalUsageForDate(yesterday);
    } catch (e) {
      print(
        'BackgroundTask: Failed to get usage data for yesterday. Error: $e',
      );
      // We will retry on the next scheduled run.
      return;
    }

    // --- 4. Prepare and Submit the Payload ---
    // Get the device's current timezone. This is sufficient for our model.
    // Note: A more advanced implementation could use a dedicated timezone package.
    final timezone = now.timeZoneName;

    print('BackgroundTask: Submitting data for $yesterdayDateString...');
    print('BackgroundTask: Final Usage: ${finalUsage.inSeconds} seconds');
    print('BackgroundTask: Timezone: $timezone');

    try {
      // Invoke the Edge Function with the prepared payload.
      await Supabase.instance.client.functions.invoke(
        'process-daily-result',
        body: {
          'date': yesterdayDateString,
          'timezone': timezone,
          'final_usage_seconds': finalUsage.inSeconds,
        },
      );

      // --- 5. Mark as Complete ---
      // If the function invoke is successful, we store today's date string
      // to prevent re-submission.
      await prefs.setString(_lastSubmissionDateKey, yesterdayDateString);
      print(
        'BackgroundTask: Successfully submitted data for $yesterdayDateString.',
      );
    } catch (e) {
      print('BackgroundTask: Failed to invoke Edge Function. Error: $e');
      // If the submission fails, we do NOT update the last submission date.
      // This ensures the task will automatically retry on its next scheduled run.
    }
  }

  /// A private helper to initialize Supabase within the background isolate.
  Future<void> _initializeSupabase() async {
    // We need to ensure dotenv is loaded to access our keys.
    await dotenv.load(fileName: ".env");
    // Initialize Supabase if it hasn't been already.
    if (Supabase.instance.client.auth.currentUser == null) {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    }
  }
}
