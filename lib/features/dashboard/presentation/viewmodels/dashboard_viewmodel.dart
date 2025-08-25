// lib/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/daily_result_providers.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';
import 'package:screenpledge/core/domain/entities/app_usage_stat.dart'; // ✅ ADDED

/// A state object that holds all the data required by the Dashboard UI.
class DashboardState {
  final Goal? activeGoal;
  final bool isGoalEffectiveNow;
  final Duration timeSpentToday;
  final List<DailyResult> weeklyResults;
  final Map<DateTime, Duration> historicalUsage;
  
  // ✅ ADDED: The detailed per-app usage breakdown for today.
  final List<AppUsageStat> dailyUsageBreakdown;

  const DashboardState({
    this.activeGoal,
    required this.isGoalEffectiveNow,
    required this.timeSpentToday,
    required this.weeklyResults,
    required this.historicalUsage,
    required this.dailyUsageBreakdown,
  });

  double get progressPercentage {
    if (activeGoal == null || activeGoal!.timeLimit.inSeconds == 0) {
      return 0.0;
    }
    final progress = timeSpentToday.inSeconds / activeGoal!.timeLimit.inSeconds;
    return progress;
  }
}

/// The main provider for the dashboard.
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
    // ✅ ADDED: Fetch the new daily usage breakdown.
    screenTimeService.getDailyUsageBreakdown(),
  ]);

  // --- Step 2: Process the fetched data ---
  debugPrint('[DashboardProvider] Step 2: Processing fetched data...');
  final goal = results[0] as Goal?;
  final weeklyResults = results[1] as List<DailyResult>;
  final historicalUsage = results[2] as Map<DateTime, Duration>;
  // ✅ ADDED: Extract the new daily usage breakdown.
  final dailyUsageBreakdown = results[3] as List<AppUsageStat>;

  debugPrint('  - Goal found: ${goal != null}');
  debugPrint('  - Historical results found: ${weeklyResults.length}');
  debugPrint('  - Historical device usage days found: ${historicalUsage.length}');
  // ✅ ADDED: Log the number of apps in the daily breakdown.
  debugPrint('  - Daily usage breakdown apps found: ${dailyUsageBreakdown.length}');

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
    
    final goalTypeString = goal.goalType == GoalType.totalTime ? 'total_time' : 'custom_group';
    final trackedPackageNames = goal.trackedApps.map((app) => app.packageName).toList();
    final exemptPackageNames = goal.exemptApps.map((app) => app.packageName).toList();

    timeSpentToday = await screenTimeService.getCountedDeviceUsage(
      goalType: goalTypeString,
      trackedPackages: trackedPackageNames,
      exemptPackages: exemptPackageNames,
    );

    debugPrint('  - Counted device usage today: $timeSpentToday');
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
    // ✅ ADDED: Pass the new daily usage breakdown to the state.
    dailyUsageBreakdown: dailyUsageBreakdown,
  );
  debugPrint('[DashboardProvider] Step 5: Final state created.');
  debugPrint('--- [DashboardProvider] END ---');
  return finalState;
});