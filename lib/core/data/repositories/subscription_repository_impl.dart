// lib/core/data/repositories/subscription_repository_impl.dart

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:screenpledge/core/data/datasources/revenuecat_remote_datasource.dart';
import 'package:screenpledge/core/domain/repositories/subscription_repository.dart';

/// The DATA layer implementation of the ISubscriptionRepository contract.
///
/// This class is the "Head Chef". It knows HOW to perform the actions
/// by delegating calls to the appropriate data source specialist(s).
class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final RevenueCatRemoteDataSource _remoteDataSource;

  SubscriptionRepositoryImpl(this._remoteDataSource);

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      // The implementation simply calls the data source method.
      // More complex logic (e.g., mapping errors, caching) could live here if needed.
      return await _remoteDataSource.purchasePackage(package);
    } catch (e) {
      // Here you could catch specific data-layer exceptions and re-throw
      // them as domain-layer failures if you had a more complex error model.
      // For now, we just re-throw.
      rethrow;
    }
  }
}