// lib/features/onboarding_post/presentation/viewmodels/user_survey_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/features/onboarding_post/di/user_survey_providers.dart';
import 'package:screenpledge/features/onboarding_post/domain/usecases/submit_user_survey.dart';

/// Manages the state and business logic for the User Survey page.
class UserSurveyViewModel extends StateNotifier<AsyncValue<void>> {
  final SubmitUserSurveyUseCase _submitUserSurveyUseCase;

  UserSurveyViewModel(this._submitUserSurveyUseCase) : super(const AsyncValue.data(null));

  /// Attempts to save the user's survey answers and display name to the backend.
  ///
  /// ✅ CHANGED: This method now requires the displayName and a map of survey answers.
  /// It passes these to the use case, which will handle the RPC call.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitSurvey({
    required String displayName,
    required Map<String, String?> answers,
  }) async {
    state = const AsyncValue.loading();
    try {
      // ✅ CHANGED: Call the use case with both the display name and the answers.
      // We create a new map and add the display name to it before passing it along.
      final fullPayload = {
        ...answers,
        'display_name': displayName,
      };
      await _submitUserSurveyUseCase(fullPayload);
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
    // The provider's dependency remains the same.
    return UserSurveyViewModel(ref.read(submitUserSurveyUseCaseProvider));
  },
);