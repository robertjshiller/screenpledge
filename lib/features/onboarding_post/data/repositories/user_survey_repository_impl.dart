// lib/features/onboarding_post/data/repositories/user_survey_repository_impl.dart

import 'package:screenpledge/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart';
import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';

/// The DATA layer implementation of the IUserSurveyRepository contract.
/// It acts as a bridge, delegating the call to the data source.
class UserSurveyRepositoryImpl implements IUserSurveyRepository {
  final UserSurveyRemoteDataSource _remoteDataSource;
  UserSurveyRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> saveSurvey(List<String?> answers) async {
    try {
      return await _remoteDataSource.saveSurvey(answers);
    } catch (e) {
      // Here you could catch specific exceptions and re-throw them as
      // custom domain-layer failures if needed. For now, we just re-throw.
      rethrow;
    }
  }
}