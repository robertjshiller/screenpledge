// lib/core/domain/repositories/goal_repository.dart

import 'package:screenpledge/core/domain/entities/goal.dart';

/// The contract (interface) for a repository that handles Goal-related data operations.
///
/// ✅ REFACTORED: This repository is now the single source of truth for goal data,
/// implementing an offline-first strategy.
abstract class IGoalRepository {
  /// A method to call the RPC that finalizes the onboarding goal.
  ///
  /// Takes an optional pledge amount. If null or 0, the pledge is considered skipped.
  Future<void> commitOnboardingGoal({int? pledgeAmountCents});

  /// Fetches the definition of the user's currently active goal.
  ///
  /// ✅ REFACTORED: This method now implements the "Sync on Resume" pattern.
  /// It will first attempt to return a goal from the local cache for an instant UI,
  /// then trigger a background fetch from the server to update the cache.
  ///
  /// [forceRefresh]: If true, it will bypass the cache and fetch directly from the network.
  ///
  /// Returns the [Goal] object if one is found, otherwise returns null.
  Future<Goal?> getActiveGoal({bool forceRefresh = false});
}