// lib/core/di/profile_providers.dart

// Original comments are retained.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/datasources/user_remote_data_source.dart';
import 'package:screenpledge/core/data/repositories/profile_repository_impl.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
import 'package:screenpledge/core/domain/usecases/save_goal_and_continue.dart';
import 'package:screenpledge/core/domain/usecases/create_stripe_setup_intent.dart';
// ✅ NEW: Import the cache repository contract and implementation.
import 'package:screenpledge/core/data/repositories/cache_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';


/// This file contains all the Riverpod providers related to user data,
/// including remote profile data and local caching.

// --- DATA LAYER (REMOTE) ---
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserRemoteDataSource(supabaseClient);
});

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ProfileRepositoryImpl(remoteDataSource, supabaseClient);
});


// ✅ NEW: A dedicated section for our caching layer.
// --- DATA LAYER (CACHE) ---

/// Provider for our concrete implementation of the cache repository.
/// This is kept private as other parts of the app should depend on the abstraction.
final _cacheRepositoryImplProvider = Provider<CacheRepositoryImpl>((ref) {
  return CacheRepositoryImpl();
});

/// The public provider for the cache repository contract [ICacheRepository].
///
/// Other layers of the app (ViewModels, UseCases) will watch this provider
/// to get the cache repository, keeping them decoupled from the concrete implementation.
final cacheRepositoryProvider = Provider<ICacheRepository>((ref) {
  return ref.watch(_cacheRepositoryImplProvider);
});


// --- DOMAIN LAYER ---

/// Provider for the SaveGoalAndContinueUseCase.
final saveGoalAndContinueUseCaseProvider = Provider<SaveGoalAndContinueUseCase>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return SaveGoalAndContinueUseCase(profileRepository);
});

/// Provider for the CreateStripeSetupIntentUseCase.
final createStripeSetupIntentUseCaseProvider = Provider<CreateStripeSetupIntentUseCase>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return CreateStripeSetupIntentUseCase(profileRepository);
});


// --- PRESENTATION LAYER (or for UI consumption) ---
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  if (authState is! AsyncData || authState.value == null) {
    return null;
  }
  final profileRepository = ref.watch(profileRepositoryProvider);
  // NOTE: In a future step, we will refactor this provider to use our
  // new cache repository for an offline-first experience.
  return await profileRepository.getMyProfile();
});