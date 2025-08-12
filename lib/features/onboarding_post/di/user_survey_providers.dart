import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
import 'package:screenpledge/core/di/profile_providers.dart'; // ✅ ADDED
import 'package:screenpledge/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart';
import 'package:screenpledge/features/onboarding_post/data/repositories/user_survey_repository_impl.dart';
import 'package:screenpledge/features/onboarding_post/domain/repositories/user_survey_repository.dart';
import 'package:screenpledge/features/onboarding_post/domain/usecases/save_user_survey.dart';

// 1. DATA Layer Provider: Provides the concrete data source.
final userSurveyRemoteDataSourceProvider = Provider<UserSurveyRemoteDataSource>((ref) {
  return UserSurveyRemoteDataSource(ref.read(supabaseClientProvider));
});

// 2. DATA Layer Provider: Provides the repository implementation.
final userSurveyRepositoryProvider = Provider<IUserSurveyRepository>((ref) {
  return UserSurveyRepositoryImpl(ref.read(userSurveyRemoteDataSourceProvider));
});

// 3. DOMAIN Layer Provider: Provides the use case.
// ✅ CHANGED: The provider now also reads the 'updateOnboardingStatusUseCaseProvider'
// and injects it into the SaveUserSurvey use case.
final saveUserSurveyUseCaseProvider = Provider<SaveUserSurvey>((ref) {
  final surveyRepository = ref.read(userSurveyRepositoryProvider);
  final updateOnboardingStatusUseCase = ref.read(updateOnboardingStatusUseCaseProvider);
  return SaveUserSurvey(surveyRepository, updateOnboardingStatusUseCase);
});