// lib/features/onboarding_post/di/user_survey_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/auth_providers.dart'; // To get the SupabaseClient
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
final saveUserSurveyUseCaseProvider = Provider<SaveUserSurvey>((ref) {
  return SaveUserSurvey(ref.read(userSurveyRepositoryProvider));
});