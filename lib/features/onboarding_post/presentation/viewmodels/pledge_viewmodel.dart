// lib/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart

// Original comments are retained.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/domain/usecases/commit_onboarding_goal.dart';
import 'package:screenpledge/core/domain/usecases/create_stripe_setup_intent.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';

/// Manages the state and business logic for the PledgePage.
class PledgeViewModel extends StateNotifier<AsyncValue<void>> {
  final CommitOnboardingGoalUseCase _commitOnboardingGoalUseCase;
  final CreateStripeSetupIntentUseCase _createStripeSetupIntentUseCase;
  final ICacheRepository _cacheRepository;
  final Ref _ref;

  PledgeViewModel(
    this._commitOnboardingGoalUseCase,
    this._createStripeSetupIntentUseCase,
    this._cacheRepository,
    this._ref,
  ) : super(const AsyncValue.data(null));

  /// Orchestrates the entire pledge activation flow.
  Future<void> savePaymentMethodAndActivatePledge({required int amountCents}) async {
    state = const AsyncValue.loading();
    try {
      // ✅ REFACTORED: Construct the goal object BEFORE any async operations.
      // This makes our flow more resilient. We now have the goal data in memory
      // before we call the RPC that will clear the draft from the profile.
      final goalToCommit = _getGoalFromDraft();
      if (goalToCommit == null) {
        throw Exception("Could not create goal from draft. Draft data is missing.");
      }

      final clientSecret = await _createStripeSetupIntentUseCase();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'ScreenPledge',
          setupIntentClientSecret: clientSecret,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // Pass the fully constructed goal object to the final activation method.
      await activatePledge(amountCents: amountCents, goalToCache: goalToCommit);

    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled) {
        state = AsyncValue.error('Payment failed: ${e.error.message}', StackTrace.current);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Handles the database commit and local caching.
  Future<void> activatePledge({
    required int amountCents,
    required Goal goalToCache,
  }) async {
    try {
      // Call the use case to save the goal to the Supabase database.
      await _commitOnboardingGoalUseCase(pledgeAmountCents: amountCents);

      // ✅ REFACTORED: The caching logic is now much simpler.
      // It receives the already-constructed Goal object and saves it.
      await _cacheRepository.saveActiveGoal(goalToCache);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Called when the user taps the 'Not Now' (skip) button.
  Future<void> skipPledge() async {
    state = const AsyncValue.loading();
    try {
      // ✅ REFACTORED: Construct the goal object first, just like in the pledge flow.
      final goalToCommit = _getGoalFromDraft();
      if (goalToCommit == null) {
        throw Exception("Could not create goal from draft. Draft data is missing.");
      }

      // Call the use case to save the goal to Supabase without a pledge.
      await _commitOnboardingGoalUseCase();

      // Also cache the goal locally when the user skips.
      await _cacheRepository.saveActiveGoal(goalToCommit);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ✅ REFACTORED: This helper method now CONSTRUCTS and RETURNS a Goal object.
  /// It no longer performs the caching itself. This separates the responsibility
  /// of data creation from data saving.
  Goal? _getGoalFromDraft() {
    final profile = _ref.read(myProfileProvider).value;
    final draftGoalData = profile?.onboardingDraftGoal;

    if (draftGoalData != null) {
      final goalTypeString = draftGoalData['goalType'] as String;
      final camelCaseGoalType = goalTypeString.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (match) => match.group(1)!.toUpperCase(),
      );

      return Goal(
        goalType: GoalType.values.byName(camelCaseGoalType),
        timeLimit: Duration(seconds: draftGoalData['timeLimit']),
        trackedApps: const {},
        exemptApps: const {},
        effectiveAt: DateTime.now(),
      );
    }
    // Return null if no draft goal data is found.
    return null;
  }
}

/// The Riverpod provider for the PledgeViewModel.
final pledgeViewModelProvider =
    StateNotifierProvider.autoDispose<PledgeViewModel, AsyncValue<void>>(
  (ref) {
    final commitOnboardingGoalUseCase = ref.watch(commitOnboardingGoalUseCaseProvider);
    final createStripeSetupIntentUseCase = ref.watch(createStripeSetupIntentUseCaseProvider);
    final cacheRepository = ref.watch(cacheRepositoryProvider);
    
    return PledgeViewModel(
      commitOnboardingGoalUseCase,
      createStripeSetupIntentUseCase,
      cacheRepository,
      ref,
    );
  },
);