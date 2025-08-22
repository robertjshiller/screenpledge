// lib/core/domain/usecases/save_goal_and_continue.dart

import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';

/// ✅ NEW: A clearly named use case for the specific action of saving the draft
/// goal during onboarding and continuing to the next step.
class SaveGoalAndContinueUseCase {
  final IProfileRepository _profileRepository;

  SaveGoalAndContinueUseCase(this._profileRepository);

  /// Executes the use case.
  Future<void> call(Goal draftGoal) async {
    // Convert the pure Goal entity into a JSON map that the RPC can accept.
    final draftGoalJson = {
      'goalType': draftGoal.goalType == GoalType.totalTime ? 'total_time' : 'custom_group',
      'timeLimit': draftGoal.timeLimit.inSeconds,
      'exemptApps': draftGoal.exemptApps.map((app) => app.toJson()).toList(),
      'trackedApps': draftGoal.trackedApps.map((app) => app.toJson()).toList(),
    };
    
    // Call the repository method that invokes the atomic RPC.
    await _profileRepository.saveOnboardingDraftGoal(draftGoalJson);
  }
}
