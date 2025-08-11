// lib/features/onboarding_pre/presentation/viewmodels/subscription_offer_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// ✅ ADD the new import to the subscription providers file
import 'package:screenpledge/core/di/subscription_providers.dart';
// ✅ And import the use case from its new core location
import 'package:screenpledge/core/domain/usecases/purchase_subscription.dart';

class SubscriptionOfferViewModel extends StateNotifier<AsyncValue<void>> {
  // ✅ ADD: The ViewModel now depends on the abstract Use Case.
  final PurchaseSubscription _purchaseSubscription;

  int selectedIndex = 1; // Default to annual plan.

  // ✅ CHANGED: Update the constructor to accept the use case.
  SubscriptionOfferViewModel(this._purchaseSubscription)
      : super(const AsyncValue.data(null));

  void selectPlan(int index) {
    selectedIndex = index;
    // This is a simple way to force the UI to rebuild and show the new selection.
    state = const AsyncValue.data(null);
  }

  /// Purchase the selected package.
  Future<void> purchase(Package package) async {
    state = const AsyncValue.loading();

    // =======================================================================
    // TESTINGNOWREPLACELATER: DEVELOPMENT ONLY - FAKE SUCCESS
    // -----------------------------------------------------------------------
    // This code simulates a successful purchase to allow UI flow testing
    // without making a real network call to RevenueCat.
    //
    // TO RE-ENABLE REAL PURCHASES:
    // 1. Delete this "FAKE SUCCESS" block.
    // 2. Uncomment the "REAL CODE" block below.
    // =======================================================================
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate loading.
    state = const AsyncValue.data(null); // Pretend the purchase was a success.
    // =======================================================================
    // END OF TESTINGNOWREPLACELATER BLOCK
    // =======================================================================


    /*
    // =======================================================================
    // TESTINGNOWREPLACELATER: REAL CODE (Currently disabled for testing)
    // -----------------------------------------------------------------------
    // This is the actual production code that calls the purchase use case.
    // Uncomment this block for release or for real purchase testing.
    // =======================================================================
    try {
      // ✅ CHANGED: Call the use case instead of the data source.
      // The ViewModel (waiter) now just orders the "menu item".
      await _purchaseSubscription(package);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    // =======================================================================
    // END OF REAL CODE BLOCK
    // =======================================================================
    */
  }
}

// ✅ CHANGED: Update the ViewModel provider to use the new use case provider.
final subscriptionOfferViewModelProvider =
    StateNotifierProvider.autoDispose<SubscriptionOfferViewModel, AsyncValue<void>>(
  (ref) {
    // It reads the use case provider...
    final purchaseUseCase = ref.read(purchaseSubscriptionUseCaseProvider);
    // ...and passes it to the ViewModel.
    return SubscriptionOfferViewModel(purchaseUseCase);
  },
);