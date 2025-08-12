import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/goal_providers.dart'; // ✅ ADDED: This import makes the provider visible to this file.
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/domain/usecases/save_goal.dart';

/// Manages the state and business logic for the GoalSettingPage.
class GoalSettingViewModel extends StateNotifier<AsyncValue<void>> {
  final SaveGoalUseCase _saveGoalUseCase;

  GoalSettingViewModel(this._saveGoalUseCase) : super(const AsyncValue.data(null));

  /// Called when the user taps the 'Save Goal' button.
  ///
  /// This method orchestrates the process of creating the Goal entity
  /// and executing the save operation.
  Future<void> saveGoal({
    required bool isTotalTime,
    required Duration timeLimit,
    required Set<InstalledApp> exemptApps,
    required Set<InstalledApp> trackedApps,
  }) async {
    // Set the state to loading to give the user feedback.
    state = const AsyncValue.loading();

    // Create the pure domain entity from the UI data.
    final goal = Goal(
      goalType: isTotalTime ? GoalType.totalTime : GoalType.customGroup,
      timeLimit: timeLimit,
      exemptApps: exemptApps,
      trackedApps: trackedApps,
    );

    try {
      // Execute the use case.
      await _saveGoalUseCase(goal);
      // If successful, set the state back to data (which signals success to the UI).
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // If an error occurs, capture it in the state.
      state = AsyncValue.error(e, st);
    }
  }
}

/// The Riverpod provider for the GoalSettingViewModel.
///
/// This is specific to the onboarding feature.
final goalSettingViewModelProvider =
    StateNotifierProvider.autoDispose<GoalSettingViewModel, AsyncValue<void>>(
  (ref) {
    // The ViewModel depends on the core use case.
    // ✅ FIXED: This line now works because the provider is imported correctly.
    final saveGoalUseCase = ref.watch(saveGoalUseCaseProvider);
    return GoalSettingViewModel(saveGoalUseCase);
  },
);