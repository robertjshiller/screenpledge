// lib/features/onboarding_post/domain/repositories/user_survey_repository.dart

/// The DOMAIN layer contract for handling user survey data operations.
abstract class IUserSurveyRepository {
  /// ✅ CHANGED: The method now takes a Map for clarity and robustness.
  /// Submits the user's survey answers to the backend.
  /// This is now an atomic operation that also updates the onboarding checkpoint.
  Future<void> submitSurvey(Map<String, String?> answers);
}