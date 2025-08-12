import 'package:screenpledge/core/domain/entities/profile.dart';

/// The contract (interface) for a repository that handles Profile-related data operations.
abstract class IProfileRepository {
  /// Fetches the profile for the currently authenticated user.
  Future<Profile> getMyProfile();

  /// ✅ ADDED: A method to update a specific onboarding status flag in the user's profile.
  ///
  /// This is a crucial part of the resilient onboarding flow.
  /// Takes a column name and a boolean value.
  Future<void> updateOnboardingStatus(String column, bool value);
}