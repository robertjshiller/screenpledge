// lib/features/onboarding_post/presentation/viewmodels/verify_email_viewmodel.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/domain/usecases/resend_otp.dart';
import 'package:screenpledge/core/domain/usecases/verify_otp.dart';
import 'package:screenpledge/core/di/auth_providers.dart';

/// Manages the state and business logic for the OTP Email Verification page.
class VerifyEmailViewModel extends StateNotifier<AsyncValue<void>> {
  final VerifyOtp _verifyOtpUseCase;
  final ResendOtp _resendOtpUseCase;

  VerifyEmailViewModel(this._verifyOtpUseCase, this._resendOtpUseCase)
      : super(const AsyncValue.data(null));

  /// Attempts to verify the user's email with the provided OTP.
  /// Returns `true` on success, `false` on failure.
  Future<bool> verifyCode({
    required String email,
    required String token,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _verifyOtpUseCase(email: email, token: token);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Attempts to resend the OTP to the user's email.
  Future<void> resendCode({required String email}) async {
    // We don't set a loading state for resend to keep the UI responsive.
    try {
      await _resendOtpUseCase(email: email);
    } catch (e, st) {
      // We can show an error, but we don't want to block the main state.
      state = AsyncValue.error(e, st);
    }
  }
}

/// The Riverpod provider for the VerifyEmailViewModel.
final verifyEmailViewModelProvider =
    StateNotifierProvider.autoDispose<VerifyEmailViewModel, AsyncValue<void>>(
  (ref) {
    final verifyOtp = ref.read(verifyOtpUseCaseProvider);
    final resendOtp = ref.read(resendOtpUseCaseProvider);
    return VerifyEmailViewModel(verifyOtp, resendOtp);
  },
);