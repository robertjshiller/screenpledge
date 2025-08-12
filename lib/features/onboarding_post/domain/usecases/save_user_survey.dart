import 'package:screenpledge/core/domain/usecases/update_onboarding_status.dart';
import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';

/// A use case that orchestrates the entire process of submitting the user survey.
class SaveUserSurvey {
  final IUserSurveyRepository _surveyRepository;
  // ✅ ADDED: A dependency on the use case for updating the profile.
  final UpdateOnboardingStatusUseCase _updateOnboardingStatus;

  SaveUserSurvey(this._surveyRepository, this._updateOnboardingStatus);

  /// Executes the use case.
  ///
  /// This now performs two distinct actions in a sequence:
  /// 1. Saves the survey answers to the `user_surveys` table.
  /// 2. Updates the `onboarding_completed_survey` flag in the `profiles` table.
  Future<void> call(List<String?> answers) async {
    // Step 1: Save the survey answers.
    await _surveyRepository.saveSurvey(answers);

    // Step 2: Update the profile to mark this onboarding step as complete.
    // This makes the onboarding flow resilient.
    await _updateOnboardingStatus('onboarding_completed_survey', true);
  }
}