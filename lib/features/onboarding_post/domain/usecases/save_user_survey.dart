// lib/features/onboarding_post/domain/usecases/save_user_survey.dart

import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';

/// The DOMAIN layer Use Case for saving the user survey.
/// This class has a single responsibility: to execute the save action.
class SaveUserSurvey {
  final IUserSurveyRepository _repository;
  SaveUserSurvey(this._repository);

  /// The `call` method makes the class callable like a function.
  Future<void> call(List<String?> answers) async {
    return await _repository.saveSurvey(answers);
  }
}