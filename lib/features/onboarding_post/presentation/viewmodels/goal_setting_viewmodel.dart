// lib/features/onboarding_post/presentation/viewmodels/goal_setting_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/profile_providers.dart'; // ✅ CHANGED: Import profile providers
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
// ✅ CHANGED: Import the new, correctly named use case.
import 'package:screenpledge/core/domain/usecases/save_goal_and_continue.dart';

/// Manages the state and business logic for the GoalSettingPage.
class GoalSettingViewModel extends StateNotifier<AsyncValue<void>> {
  // ✅ CHANGED: The dependency is now the new, clearly named use case.
  final SaveGoalAndContinueUseCase _saveGoalAndContinueUseCase;

  GoalSettingViewModel(this._saveGoalAndContinueUseCase) : super(const AsyncValue.data(null));

  /// ✅ CHANGED: Renamed to match the use case and clarify its purpose.
  ///
  /// This method now saves the user's goal configuration as a "draft" in their
  /// profile and marks the goal setup step of onboarding as complete in a single
  /// atomic transaction.
  Future<void> saveDraftGoalAndContinue({
    required bool isTotalTime,
    required Duration timeLimit,
    required Set<InstalledApp> exemptApps,
    required Set<InstalledApp> trackedApps,
  }) async {
    state = const AsyncValue.loading();

    // Create the pure domain entity from the UI data. This is the "draft goal".
    final draftGoal = Goal(
      goalType: isTotalTime ? GoalType.totalTime : GoalType.customGroup,
      timeLimit: timeLimit,
      exemptApps: exemptApps,
      trackedApps: trackedApps,
    );

    try {
      // Execute the use case to save the draft and update the flag via the RPC.
      await _saveGoalAndContinueUseCase(draftGoal);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// The Riverpod provider for the GoalSettingViewModel.
final goalSettingViewModelProvider =
    StateNotifierProvider.autoDispose<GoalSettingViewModel, AsyncValue<void>>(
  (ref) {
    // ✅ CHANGED: The provider now watches the new saveGoalAndContinueUseCaseProvider.
    final saveGoalAndContinueUseCase = ref.watch(saveGoalAndContinueUseCaseProvider);
    return GoalSettingViewModel(saveGoalAndContinueUseCase);
  },
);