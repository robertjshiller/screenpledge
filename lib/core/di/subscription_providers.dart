// lib/core/di/subscription_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/datasources/revenuecat_remote_datasource.dart';
import 'package:screenpledge/core/data/repositories/subscription_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/subscription_repository.dart';
import 'package:screenpledge/core/domain/usecases/purchase_subscription.dart';

// --- REPOSITORY PROVIDER for the Subscription Domain ---

final subscriptionRepositoryProvider = Provider<ISubscriptionRepository>((ref) {
  final remoteDataSource = ref.read(revenueCatRemoteDataSourceProvider);
  return SubscriptionRepositoryImpl(remoteDataSource);
});


// --- USE CASE PROVIDER(s) for the Subscription Domain ---

final purchaseSubscriptionUseCaseProvider = Provider<PurchaseSubscription>((ref) {
  final repository = ref.read(subscriptionRepositoryProvider);
  return PurchaseSubscription(repository);
});