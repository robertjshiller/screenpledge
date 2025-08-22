import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';

/// ✅ NEW: A clearly named use case for the specific action of submitting the survey.
///
/// This use case orchestrates the entire process of submitting the user survey
/// by calling the repository. Its purpose is singular and clear.
class SubmitUserSurveyUseCase {
  final IUserSurveyRepository _surveyRepository;

  SubmitUserSurveyUseCase(this._surveyRepository);

  /// Executes the use case.
  Future<void> call(Map<String, String?> answers) async {
    await _surveyRepository.submitSurvey(answers);
  }
}
