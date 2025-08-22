// lib/core/domain/repositories/profile_repository.dart

import 'package:screenpledge/core/domain/entities/profile.dart';

/// The contract (interface) for a repository that handles Profile-related data operations.
abstract class IProfileRepository {
  /// Fetches the profile for the currently authenticated user.
  Future<Profile> getMyProfile();

  /// ✅ CHANGED: This method is no longer needed as its logic is now handled by specific RPCs.
  /// We are keeping it for now in case other parts of the app use it, but it should be deprecated.
  /// Future<void> updateOnboardingStatus(String column, bool value);

  /// ✅ ADDED: A dedicated method to save the draft goal and update the flag via an RPC.
  Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal);
}
