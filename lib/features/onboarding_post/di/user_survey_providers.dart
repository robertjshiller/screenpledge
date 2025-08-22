import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
import 'package:screenpledge/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart';
import 'package:screenpledge/features/onboarding_post/data/repositories/user_survey_repository_impl.dart';
import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';
// ✅ CHANGED: Import the new, correctly named use case.
import 'package:screenpledge/features/onboarding_post/domain/usecases/submit_user_survey.dart';

// 1. DATA Layer Provider: Provides the concrete data source.
final userSurveyRemoteDataSourceProvider = Provider<UserSurveyRemoteDataSource>((ref) {
  return UserSurveyRemoteDataSource(ref.read(supabaseClientProvider));
});

// 2. DATA Layer Provider: Provides the repository implementation.
final userSurveyRepositoryProvider = Provider<IUserSurveyRepository>((ref) {
  return UserSurveyRepositoryImpl(ref.read(userSurveyRemoteDataSourceProvider));
});

// 3. DOMAIN Layer Provider: Provides the use case.
// ✅ CHANGED: This provider now creates and provides the new SubmitUserSurveyUseCase.
final submitUserSurveyUseCaseProvider = Provider<SubmitUserSurveyUseCase>((ref) {
  return SubmitUserSurveyUseCase(ref.read(userSurveyRepositoryProvider));
});