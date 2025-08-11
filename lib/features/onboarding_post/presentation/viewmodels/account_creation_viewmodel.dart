// lib/features/onboarding_post/presentation/viewmodels/account_creation_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
import 'package:screenpledge/core/domain/usecases/sign_up.dart';

// ✅ ADDED: An enum to represent the result of a sign-up attempt.
// This allows the UI to know how to navigate.
enum SignUpResult {
  successNeedsVerification, // For email/password sign-up
  successVerified,          // For OAuth (Google/Apple) sign-up
  failure,
}

/// Manages the state and business logic for the Account Creation page.
class AccountCreationViewModel extends StateNotifier<AsyncValue<void>> {
  final SignUp _signUpUseCase;

  AccountCreationViewModel(this._signUpUseCase) : super(const AsyncValue.data(null));

  /// Attempts to create a new user account with the provided credentials.
  /// Returns a [SignUpResult] to inform the UI of the outcome.
  Future<SignUpResult> signUpUser({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Call the use case to create the user in Supabase.
      final user = await _signUpUseCase(email: email, password: password);

      // 2. CRITICAL HANDOFF: Tell RevenueCat who this user is.
      await Purchases.logIn(user.id);

      // 3. TODO: Call the backend Edge Function (Task 3.1)

      state = const AsyncValue.data(null);
      // ✅ CHANGED: Return the specific result for email sign-up.
      return SignUpResult.successNeedsVerification;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return SignUpResult.failure;
    }
  }

  // TODO: Implement signUpWithGoogle and signUpWithApple methods.
  // These would call different use cases and return SignUpResult.successVerified.
}

/// The Riverpod provider for the AccountCreationViewModel.
final accountCreationViewModelProvider =
    StateNotifierProvider.autoDispose<AccountCreationViewModel, AsyncValue<void>>(
  (ref) {
    return AccountCreationViewModel(ref.read(signUpUseCaseProvider));
  },
);