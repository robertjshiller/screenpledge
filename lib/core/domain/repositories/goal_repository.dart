// lib/core/domain/repositories/goal_repository.dart

import 'package:screenpledge/core/domain/entities/goal.dart';

/// The contract (interface) for a repository that handles Goal-related data operations.
abstract class IGoalRepository {
  /// A method to call the RPC that finalizes the onboarding goal.
  ///
  /// Takes an optional pledge amount. If null or 0, the pledge is considered skipped.
  Future<void> commitOnboardingGoal({int? pledgeAmountCents});

  /// Fetches the definition of the user's currently active goal.
  ///
  /// Returns the [Goal] object if one is found, otherwise returns null.
  Future<Goal?> getActiveGoal();
}
