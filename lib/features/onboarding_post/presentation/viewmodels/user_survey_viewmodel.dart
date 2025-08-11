// lib/features/onboarding_post/presentation/viewmodels/user_survey_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/features/onboarding_post/di/user_survey_providers.dart';
import 'package:screenpledge/features/onboarding_post/domain/usecases/save_user_survey.dart';

/// Manages the state and business logic for the User Survey page.
class UserSurveyViewModel extends StateNotifier<AsyncValue<void>> {
  final SaveUserSurvey _saveUserSurveyUseCase;

  UserSurveyViewModel(this._saveUserSurveyUseCase) : super(const AsyncValue.data(null));

  /// Attempts to save the user's survey answers to the backend.
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitSurvey(List<String?> answers) async {
    state = const AsyncValue.loading();
    try {
      await _saveUserSurveyUseCase(answers);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// The Riverpod provider for the UserSurveyViewModel.
final userSurveyViewModelProvider =
    StateNotifierProvider.autoDispose<UserSurveyViewModel, AsyncValue<void>>(
  (ref) {
    return UserSurveyViewModel(ref.read(saveUserSurveyUseCaseProvider));
  },
);