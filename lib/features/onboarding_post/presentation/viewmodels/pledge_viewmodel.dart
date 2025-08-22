// lib/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/domain/usecases/commit_onboarding_goal.dart';

/// Manages the state and business logic for the PledgePage.
class PledgeViewModel extends StateNotifier<AsyncValue<void>> {
  final CommitOnboardingGoalUseCase _commitOnboardingGoalUseCase;

  PledgeViewModel(this._commitOnboardingGoalUseCase) : super(const AsyncValue.data(null));

  /// Called when the user taps the 'Activate My Pledge' button.
  Future<void> activatePledge({required int amountCents}) async {
    state = const AsyncValue.loading();
    try {
      // Call the use case, passing the selected pledge amount.
      await _commitOnboardingGoalUseCase(pledgeAmountCents: amountCents);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Called when the user taps the 'Not Now' (skip) button.
  Future<void> skipPledge() async {
    state = const AsyncValue.loading();
    try {
      // Call the use case without a pledge amount. The RPC will handle this correctly.
      await _commitOnboardingGoalUseCase();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// The Riverpod provider for the PledgeViewModel.
final pledgeViewModelProvider =
    StateNotifierProvider.autoDispose<PledgeViewModel, AsyncValue<void>>(
  (ref) {
    final commitOnboardingGoalUseCase = ref.watch(commitOnboardingGoalUseCaseProvider);
    return PledgeViewModel(commitOnboardingGoalUseCase);
  },
);