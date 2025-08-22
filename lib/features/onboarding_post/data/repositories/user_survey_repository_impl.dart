// lib/features/onboarding_post/data/repositories/user_survey_repository_impl.dart

import 'package:screenpledge/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart';
import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';

/// The DATA layer implementation of the IUserSurveyRepository contract.
class UserSurveyRepositoryImpl implements IUserSurveyRepository {
  final UserSurveyRemoteDataSource _remoteDataSource;
  UserSurveyRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> submitSurvey(Map<String, String?> answers) async {
    // The implementation remains simple: delegate the call to the data source.
    // Error handling is managed by the ViewModel layer.
    try {
      return await _remoteDataSource.submitSurvey(answers);
    } catch (e) {
      rethrow;
    }
  }
}