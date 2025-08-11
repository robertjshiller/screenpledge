// lib/core/domain/repositories/subscription_repository.dart

import 'package:purchases_flutter/purchases_flutter.dart';

/// The DOMAIN layer contract for handling subscription-related data operations.
///
/// This abstract class defines WHAT needs to be done, but not HOW.
/// The Presentation layer will depend on this, and the Data layer will implement it.
/// It's the formal "job description" for a subscription manager.
abstract class ISubscriptionRepository {
  /// Purchase a package and return the updated customer info.
  /// Throws an exception if the purchase fails.
  Future<CustomerInfo> purchasePackage(Package package);

  // In the future, other subscription-related contracts would go here, like:
  // Future<bool> hasPremiumAccess();
  // Stream<CustomerInfo> get customerInfoStream;
}