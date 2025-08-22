// lib/features/onboarding_post/presentation/viewmodels/goal_setting_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/domain/usecases/save_goal_and_continue.dart';

/// Manages the state and business logic for the GoalSettingPage.
class GoalSettingViewModel extends StateNotifier<AsyncValue<void>> {
  final SaveGoalAndContinueUseCase _saveGoalAndContinueUseCase;

  GoalSettingViewModel(this._saveGoalAndContinueUseCase) : super(const AsyncValue.data(null));

  /// Saves the user's goal configuration as a "draft" in their
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
    // ✅ FIXED: Added the new, required `effectiveAt` field.
    // For a new goal created during onboarding, this should be the current time.
    // We also explicitly set `endedAt` to null for clarity.
    final draftGoal = Goal(
      goalType: isTotalTime ? GoalType.totalTime : GoalType.customGroup,
      timeLimit: timeLimit,
      exemptApps: exemptApps,
      trackedApps: trackedApps,
      effectiveAt: DateTime.now(), // This is the required value.
      endedAt: null,
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
    final saveGoalAndContinueUseCase = ref.watch(saveGoalAndContinueUseCaseProvider);
    return GoalSettingViewModel(saveGoalAndContinueUseCase);
  },
);