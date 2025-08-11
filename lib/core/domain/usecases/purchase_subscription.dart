// lib/core/usecases/purchase_subscription.dart

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:screenpledge/core/domain/repositories/subscription_repository.dart';

/// The DOMAIN layer Use Case for purchasing a subscription.
///
/// This class has a single responsibility: to execute the purchase action
/// by calling the method defined in the repository contract.
/// This is the "menu item" the UI will order.
class PurchaseSubscription {
  final ISubscriptionRepository _repository;

  PurchaseSubscription(this._repository);

  /// The `call` method makes the class callable like a function.
  /// It takes the order from the UI and passes it to the repository.
  Future<CustomerInfo> call(Package package) async {
    return await _repository.purchasePackage(package);
  }
}