// lib/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/domain/entities/active_goal.dart';

/// A provider that encapsulates the logic for the dashboard.
///
/// It watches the active goal definition, combines it with screen time data,
/// and provides the final [ActiveGoal] state for the UI. This is a more
/// direct and idiomatic Riverpod approach than using a separate StateNotifier.
final dashboardProvider = FutureProvider.autoDispose<ActiveGoal?>((ref) async {
  // 1. Watch the provider that fetches the goal definition. `await` handles the future.
  final goal = await ref.watch(activeGoalProvider.future);

  // 2. If there's no goal, we can return null. The UI will handle this state.
  if (goal == null) {
    return null;
  }

  // 3. --- FAKE DATA ---
  // This is the placeholder for the real ScreenTimeService call.
  const fakeTimeSpent = Duration(minutes: 45);
  // --- END FAKE DATA ---

  // 4. Return the final ActiveGoal. The FutureProvider automatically provides
  // this as an AsyncValue to the UI, handling loading/error states.
  return ActiveGoal(
    timeLimit: goal.timeLimit,
    timeSpent: fakeTimeSpent,
  );
});
