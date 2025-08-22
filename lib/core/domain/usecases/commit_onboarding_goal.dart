// lib/core/domain/usecases/commit_onboarding_goal.dart

import 'package:screenpledge/core/domain/repositories/goal_repository.dart';

/// ✅ NEW: A clearly named use case for the final action of committing the
/// onboarding goal and pledge.
class CommitOnboardingGoalUseCase {
  final IGoalRepository _goalRepository;

  CommitOnboardingGoalUseCase(this._goalRepository);

  /// Executes the use case.
  Future<void> call({int? pledgeAmountCents}) async {
    await _goalRepository.commitOnboardingGoal(pledgeAmountCents: pledgeAmountCents);
  }
}