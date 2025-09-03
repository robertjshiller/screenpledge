// lib/features/onboarding_post/presentation/viewmodels/goal_setting_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screen_time_channel/installed_app.dart';
import 'package:screenpledge/core/domain/usecases/save_goal_and_continue.dart';

/// Manages the state and business logic for the GoalSettingPage.
class GoalSettingViewModel extends StateNotifier<AsyncValue<void>> {
  final SaveGoalAndContinueUseCase _saveGoalAndContinueUseCase;
  final Ref _ref;

  GoalSettingViewModel(this._saveGoalAndContinueUseCase, this._ref)
      : super(const AsyncValue.data(null));

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

    final draftGoal = Goal(
      goalType: isTotalTime ? GoalType.totalTime : GoalType.customGroup,
      timeLimit: timeLimit,
      exemptApps: exemptApps,
      trackedApps: trackedApps,
      effectiveAt: DateTime.now(),
      endedAt: null,
    );

    try {
      // Execute the use case to save the draft to the Supabase database.
      await _saveGoalAndContinueUseCase(draftGoal);

      // ✅ THE DEFINITIVE FIX: Use `ref.refresh` and `await` it.
      //
      // `ref.invalidate()` simply marks the provider as dirty for a future rebuild.
      // `ref.refresh()` immediately starts the refetch and returns a Future
      // that completes only when the new data has been fetched.
      //
      // By `await`ing this, we explicitly pause execution here until the
      // myProfileProvider has successfully re-fetched the profile from the
      // server, guaranteeing that the `onboardingDraftGoal` is available
      // before we navigate to the next page. This resolves the race condition.
      await _ref.refresh(myProfileProvider.future);

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
    return GoalSettingViewModel(saveGoalAndContinueUseCase, ref);
  },
);