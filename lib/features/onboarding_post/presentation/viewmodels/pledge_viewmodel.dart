// lib/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart

// Original comments are retained.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/domain/usecases/commit_onboarding_goal.dart';
import 'package:screenpledge/core/domain/usecases/create_stripe_setup_intent.dart';
// ✅ NEW: Import the Goal entity to construct our cached goal.
import 'package:screenpledge/core/domain/entities/goal.dart';
// ✅ NEW: Import the cache repository contract.
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';

/// Manages the state and business logic for the PledgePage.
class PledgeViewModel extends StateNotifier<AsyncValue<void>> {
  final CommitOnboardingGoalUseCase _commitOnboardingGoalUseCase;
  final CreateStripeSetupIntentUseCase _createStripeSetupIntentUseCase;
  // ✅ NEW: Add a dependency for our cache repository.
  final ICacheRepository _cacheRepository;
  // ✅ NEW: Add a dependency to read the user's draft goal from their profile.
  final Ref _ref;

  PledgeViewModel(
    this._commitOnboardingGoalUseCase,
    this._createStripeSetupIntentUseCase,
    // ✅ NEW: Inject the new dependencies via the constructor.
    this._cacheRepository,
    this._ref,
  ) : super(const AsyncValue.data(null));

  /// It orchestrates the entire pledge activation flow:
  /// 1. Fetches a client secret from our backend.
  /// 2. Presents the Stripe payment sheet to the user.
  /// 3. If successful, calls the original `activatePledge` to finalize in our DB and cache.
  Future<void> savePaymentMethodAndActivatePledge({required int amountCents}) async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch the client secret from our Supabase Edge Function.
      final clientSecret = await _createStripeSetupIntentUseCase();

      // 2. Initialize the Stripe payment sheet with the secret.
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'ScreenPledge',
          setupIntentClientSecret: clientSecret,
        ),
      );

      // 3. Present the payment sheet to the user.
      await Stripe.instance.presentPaymentSheet();

      // 4. If successful, finalize the pledge.
      await activatePledge(amountCents: amountCents);

    } on StripeException catch (e) {
      // Handle Stripe errors.
      if (e.error.code != FailureCode.Canceled) {
        state = AsyncValue.error('Payment failed: ${e.error.message}', StackTrace.current);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      // Handle any other errors.
      state = AsyncValue.error(e, st);
    }
  }

  /// This function now handles the database commit AND the local caching.
  Future<void> activatePledge({required int amountCents}) async {
    try {
      // Call the use case to save the goal to the Supabase database.
      await _commitOnboardingGoalUseCase(pledgeAmountCents: amountCents);

      // ✅ NEW: After the server call is successful, save the goal to the local cache.
      await _cacheActiveGoal();

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
      // Call the use case to save the goal to Supabase without a pledge.
      await _commitOnboardingGoalUseCase();

      // ✅ NEW: Also cache the goal locally when the user skips.
      await _cacheActiveGoal();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ✅ NEW: A private helper method to handle the caching logic.
  /// This reads the user's draft goal from their profile state and saves it
  /// to the local cache as the new active goal.
  Future<void> _cacheActiveGoal() async {
    // Read the current profile state to access the draft goal data.
    final profile = _ref.read(myProfileProvider).value;
    final draftGoalData = profile?.onboardingDraftGoal;

    if (draftGoalData != null) {
      // Construct a Goal entity from the draft data.
      // This will be the goal that becomes active at midnight.
      final goalToCache = Goal(
        goalType: GoalType.values.byName(draftGoalData['goalType']),
        timeLimit: Duration(seconds: draftGoalData['timeLimit']),
        // The background task doesn't need the app lists, so we can use empty sets.
        trackedApps: const {},
        exemptApps: const {},
        // The goal becomes effective now, but the "Next Day Rule" is enforced by
        // the server and the daily reset logic.
        effectiveAt: DateTime.now(),
      );

      // Use the cache repository to save the newly created goal.
      await _cacheRepository.saveActiveGoal(goalToCache);
    }
  }
}

/// The Riverpod provider for the PledgeViewModel.
final pledgeViewModelProvider =
    StateNotifierProvider.autoDispose<PledgeViewModel, AsyncValue<void>>(
  (ref) {
    final commitOnboardingGoalUseCase = ref.watch(commitOnboardingGoalUseCaseProvider);
    final createStripeSetupIntentUseCase = ref.watch(createStripeSetupIntentUseCaseProvider);
    // ✅ NEW: Watch the provider for our new cache repository.
    final cacheRepository = ref.watch(cacheRepositoryProvider);
    
    // ✅ NEW: Pass the cache repository and the ref itself to the ViewModel's constructor.
    return PledgeViewModel(
      commitOnboardingGoalUseCase,
      createStripeSetupIntentUseCase,
      cacheRepository,
      ref, // Pass ref so the ViewModel can read other providers.
    );
  },
);