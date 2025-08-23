// lib/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/daily_result_providers.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// A state object that holds all the data required by the Dashboard UI.
///
/// This is an immutable object that combines data from multiple asynchronous sources
/// into a single, easy-to-use object for the presentation layer.
class DashboardState {
  /// The user's currently active goal from the database. Can be null.
  final Goal? activeGoal;

  /// A flag indicating if the active goal's `effective_at` date has passed.
  /// This determines whether to show the "Goal Pending" or "Active Goal" UI.
  final bool isGoalEffectiveNow;

  /// The user's screen time usage for today, calculated according to their goal.
  final Duration timeSpentToday;

  /// The list of recorded results from the last 7 days for the weekly chart.
  final List<DailyResult> weeklyResults;

  /// ✅ ADDED: A map of raw historical usage data from the device.
  /// This is used to power the "Device-First" bar chart for new users.
  final Map<DateTime, Duration> historicalUsage;

  const DashboardState({
    this.activeGoal,
    required this.isGoalEffectiveNow,
    required this.timeSpentToday,
    required this.weeklyResults,
    required this.historicalUsage,
  });

  /// A computed property to get the progress percentage of time used (0.0 to 1.0+).
  double get progressPercentage {
    if (activeGoal == null || activeGoal!.timeLimit.inSeconds == 0) {
      return 0.0;
    }
    final progress = timeSpentToday.inSeconds / activeGoal!.timeLimit.inSeconds;
    return progress;
  }
}

/// The main provider for the dashboard.
///
/// This is a [FutureProvider] that orchestrates fetching all the necessary data
/// from different sources and combines them into a single [DashboardState] object.
final dashboardProvider = FutureProvider.autoDispose<DashboardState>((ref) async {
  debugPrint('--- [DashboardProvider] START ---');
  final screenTimeService = ref.read(screenTimeServiceProvider);

  // --- Step 1: Fetch all data sources in parallel for performance ---
  debugPrint('[DashboardProvider] Step 1: Fetching all data sources in parallel...');
  
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 6));

  // Use Future.wait to run these independent fetches concurrently.
  final results = await Future.wait([
    ref.watch(activeGoalProvider.future),
    ref.read(getLast7DaysResultsUseCaseProvider)(),
    screenTimeService.getUsageForDateRange(sevenDaysAgo, now),
  ]);

  // --- Step 2: Process the fetched data ---
  debugPrint('[DashboardProvider] Step 2: Processing fetched data...');
  final goal = results[0] as Goal?;
  final weeklyResults = results[1] as List<DailyResult>;
  final historicalUsage = results[2] as Map<DateTime, Duration>;

  debugPrint('  - Goal found: ${goal != null}');
  debugPrint('  - Historical results found: ${weeklyResults.length}');
  debugPrint('  - Historical device usage days found: ${historicalUsage.length}');

  // --- Step 3: Determine if the goal is currently effective ---
  bool isGoalEffectiveNow = false;
  if (goal != null) {
    isGoalEffectiveNow = goal.effectiveAt.isBefore(now);
  }
  debugPrint('[DashboardProvider] Step 3: Is goal effective now? $isGoalEffectiveNow');

  // --- Step 4: Calculate today's live usage (only if the goal is effective) ---
  Duration timeSpentToday = Duration.zero;
  if (goal != null && isGoalEffectiveNow) {
    debugPrint('[DashboardProvider] Step 4: Goal is effective. Calculating live usage for today...');
    if (goal.goalType == GoalType.totalTime) {
      final totalUsage = await screenTimeService.getTotalDeviceUsage();
      final exemptPackageNames = goal.exemptApps.map((app) => app.packageName).toList();
      final exemptUsage = await screenTimeService.getUsageForApps(exemptPackageNames);
      timeSpentToday = totalUsage - exemptUsage;
      if (timeSpentToday.isNegative) timeSpentToday = Duration.zero;
      debugPrint('  - Total Time calculation: $totalUsage - $exemptUsage = $timeSpentToday');
    } else {
      final trackedPackageNames = goal.trackedApps.map((app) => app.packageName).toList();
      timeSpentToday = await screenTimeService.getUsageForApps(trackedPackageNames);
      debugPrint('  - Custom Group calculation: Time spent = $timeSpentToday');
    }
  } else {
    debugPrint('[DashboardProvider] Step 4: Goal is not effective yet. Skipping live usage fetch.');
  }

  // --- Step 5: Construct and return the final state object ---
  final finalState = DashboardState(
    activeGoal: goal,
    isGoalEffectiveNow: isGoalEffectiveNow,
    timeSpentToday: timeSpentToday,
    weeklyResults: weeklyResults,
    historicalUsage: historicalUsage,
  );
  debugPrint('[DashboardProvider] Step 5: Final state created.');
  debugPrint('--- [DashboardProvider] END ---');
  return finalState;
});