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
import 'package:screenpledge/core/data/repositories/cache_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';


/// This file contains all the Riverpod providers related to user data,
/// including remote profile data and local caching.

// --- DATA LAYER (REMOTE) ---
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserRemoteDataSource(supabaseClient);
});

/// ✅ REFACTORED: The ProfileRepository provider now also depends on the ICacheRepository.
final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  // Watch our cache repository provider.
  final cacheRepository = ref.watch(cacheRepositoryProvider);
  // Inject all three dependencies.
  return ProfileRepositoryImpl(remoteDataSource, supabaseClient, cacheRepository);
});


// --- DATA LAYER (CACHE) ---

/// Provider for our concrete implementation of the cache repository.
final _cacheRepositoryImplProvider = Provider<CacheRepositoryImpl>((ref) {
  return CacheRepositoryImpl();
});

/// The public provider for the cache repository contract [ICacheRepository].
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

/// ✅ REFACTORED: The myProfileProvider now correctly uses the offline-first repository.
/// It no longer needs to check the auth state itself, as that logic is now
/// encapsulated within the repository's getMyProfile method.
final myProfileProvider = FutureProvider<Profile?>((ref) {
  // Simply watch the repository provider.
  final profileRepository = ref.watch(profileRepositoryProvider);
  // The getMyProfile method will handle everything: loading from cache,
  // syncing in the background, and returning the most up-to-date profile.
  try {
    return profileRepository.getMyProfile();
  } catch (e) {
    // If the repository throws (e.g., user is offline and cache is empty),
    // the FutureProvider will automatically be in an error state, which the UI can handle.
    return null;
  }
});