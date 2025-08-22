// lib/features/onboarding_post/presentation/viewmodels/user_survey_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/features/onboarding_post/di/user_survey_providers.dart';
// ✅ CHANGED: Import the new use case.
import 'package:screenpledge/features/onboarding_post/domain/usecases/submit_user_survey.dart';

/// Manages the state and business logic for the User Survey page.
class UserSurveyViewModel extends StateNotifier<AsyncValue<void>> {
  // ✅ CHANGED: The dependency is now the new use case.
  final SubmitUserSurveyUseCase _submitUserSurveyUseCase;

  UserSurveyViewModel(this._submitUserSurveyUseCase) : super(const AsyncValue.data(null));

  /// Attempts to save the user's survey answers to the backend.
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitSurvey(Map<String, String?> answers) async {
    state = const AsyncValue.loading();
    try {
      // ✅ CHANGED: Call the new use case.
      await _submitUserSurveyUseCase(answers);
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
    // ✅ CHANGED: The provider now reads the new use case provider.
    return UserSurveyViewModel(ref.read(submitUserSurveyUseCaseProvider));
  },
);