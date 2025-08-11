// lib/features/onboarding_post/domain/repositories/user_survey_repository.dart

/// The DOMAIN layer contract for handling user survey data operations.
/// This defines WHAT needs to be done, but not HOW.
abstract class IUserSurveyRepository {
  /// Saves the user's survey answers to the backend.
  /// Throws an exception if the operation fails.
  Future<void> saveSurvey(List<String?> answers);
}