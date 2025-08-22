// lib/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/daily_result_providers.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// A state object that holds all the data required by the Dashboard UI.
///
/// This is an immutable object, which is a best practice for state management.
/// It combines data from multiple sources (Supabase and the device's native APIs)
/// into a single, easy-to-use object for the presentation layer.
class DashboardState {
  /// The user's currently active goal. Can be null if no goal is set.
  final Goal? activeGoal;

  /// The user's screen time usage for today, calculated according to their goal.
  final Duration timeSpentToday;

  /// The list of results from the last 7 days for the weekly chart.
  final List<DailyResult> weeklyResults;

  const DashboardState({
    this.activeGoal,
    required this.timeSpentToday,
    required this.weeklyResults,
  });

  /// A computed property to get the progress percentage of time used (0.0 to 1.0).
  /// This is useful for determining the color of the progress ring.
  double get progressPercentage {
    if (activeGoal == null || activeGoal!.timeLimit.inSeconds == 0) {
      return 0.0;
    }
    final progress = timeSpentToday.inSeconds / activeGoal!.timeLimit.inSeconds;
    // We don't clamp here, so the UI can know if the user has gone over their limit.
    return progress;
  }
}

/// The main provider for the dashboard.
///
/// This is a [FutureProvider] that orchestrates fetching all the necessary data
/// from different sources and combines them into a single [DashboardState] object.
/// It acts as the "ViewModel" for the dashboard.
final dashboardProvider = FutureProvider.autoDispose<DashboardState>((
  ref,
) async {
  // This provider will re-run automatically if any of the providers it watches change.
  // For example, if the activeGoalProvider is invalidated, this will refetch all data.

  // 1. Fetch the user's active goal definition from Supabase.
  // We watch the `activeGoalProvider.future` to get the result of the async operation.
  final goal = await ref.watch(activeGoalProvider.future);

  // 2. Fetch the results for the last 7 days for the bar chart.
  // We use `ref.read` here because this data is less likely to change during the session.
  final weeklyResults = await ref.read(getLast7DaysResultsUseCaseProvider)();

  // 3. If there's no active goal, we can stop here and return a state
  // that reflects this. The UI will know to show a "No goal set" message.
  if (goal == null) {
    return DashboardState(
      activeGoal: null,
      timeSpentToday: Duration.zero,
      weeklyResults: weeklyResults,
    );
  }

  // 4. Fetch today's screen time from the device, based on the goal type.
  final screenTimeService = ref.read(screenTimeServiceProvider);
  Duration timeSpentToday;

  // This is the core business logic for calculating today's progress.
  if (goal.goalType == GoalType.totalTime) {
    // For a "Total Time" goal, get total usage and subtract exempt apps.
    final totalUsage = await screenTimeService.getTotalDeviceUsage();

    // We need the package names from the exempt apps list.
    final exemptPackageNames = goal.exemptApps
        .map((app) => app.packageName)
        .toList();
    final exemptUsage = await screenTimeService.getUsageForApps(
      exemptPackageNames,
    );

    timeSpentToday = totalUsage - exemptUsage;
    // Ensure duration doesn't go negative if there's an overlap in reporting.
    if (timeSpentToday.isNegative) {
      timeSpentToday = Duration.zero;
    }
  } else {
    // For a "Custom Group" goal, get usage only for the tracked apps.
    final trackedPackageNames = goal.trackedApps
        .map((app) => app.packageName)
        .toList();
    timeSpentToday = await screenTimeService.getUsageForApps(
      trackedPackageNames,
    );
  }

  // 5. Combine all the fetched and calculated data into the final state object and return it.
  // The UI will receive this object and have everything it needs to render.
  return DashboardState(
    activeGoal: goal,
    timeSpentToday: timeSpentToday,
    weeklyResults: weeklyResults,
  );
});
