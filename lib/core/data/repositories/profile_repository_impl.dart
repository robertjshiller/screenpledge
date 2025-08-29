// lib/core/data/repositories/profile_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/data/datasources/user_remote_data_source.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';

/// ✅ REFACTORED: This is the offline-first implementation of the [IProfileRepository].
///
/// This class now orchestrates fetching the user's profile from both the local cache
/// and the remote Supabase server.
class ProfileRepositoryImpl implements IProfileRepository {
  final UserRemoteDataSource _remoteDataSource;
  final SupabaseClient _supabaseClient;
  // ✅ NEW: Add a dependency on the cache repository contract.
  final ICacheRepository _cacheRepository;

  ProfileRepositoryImpl(
    this._remoteDataSource,
    this._supabaseClient,
    // ✅ NEW: Inject the cache repository.
    this._cacheRepository,
  );

  /// Fetches the profile for the currently authenticated user using an offline-first strategy.
  @override
  Future<Profile> getMyProfile({bool forceRefresh = false}) async {
    // This is the "Sync on Resume" pattern.

    // --- Step 1: Immediately try to load from the cache for an instant UI. ---
    if (!forceRefresh) {
      final cachedProfile = await _cacheRepository.getProfile();
      if (cachedProfile != null) {
        // If we have a cached profile, return it immediately.
        // Then, trigger a background sync to get the latest data.
        // We don't await this, it runs in the background.
        _fetchAndCacheFreshProfile();
        return cachedProfile;
      }
    }

    // --- Step 2: If cache is empty or a refresh is forced, fetch from network. ---
    return await _fetchAndCacheFreshProfile();
  }

  /// A private helper method to handle the network fetching and caching logic for the profile.
  Future<Profile> _fetchAndCacheFreshProfile() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        // If the user is logged out, clear any old cached profile and throw.
        await _cacheRepository.clearProfile();
        throw const AuthException('No authenticated user found.');
      }

      // --- Fetch fresh data from Supabase ---
      final rawProfileData = await _remoteDataSource.getProfile(userId);
      final freshProfile = Profile.fromMap(rawProfileData);

      // --- Cache the fresh data ---
      await _cacheRepository.saveProfile(freshProfile);

      return freshProfile;
    } catch (e) {
      // If the network fails, try to fall back to the cache one last time.
      final cachedProfile = await _cacheRepository.getProfile();
      if (cachedProfile != null) return cachedProfile;
      // If network fails AND cache is empty, we must throw the error.
      rethrow;
    }
  }

  /// The concrete implementation for saving the draft goal via an RPC.
  /// This is a "write-through" operation and doesn't involve the cache directly.
  @override
  Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal) async {
    try {
      // This calls our RPC, passing the draft goal data.
      // The server-side function handles the atomic update.
      await _supabaseClient.rpc(
        'save_onboarding_goal_draft',
        params: {'draft_goal_data': draftGoal},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// The concrete implementation for creating the Stripe Setup Intent.
  /// This is a "write-through" operation.
  @override
  Future<String> createStripeSetupIntent() async {
    try {
      // Invoke the Supabase Edge Function we created.
      final response = await _supabaseClient.functions.invoke('create-stripe-setup-intent');

      // Check for errors from the function response.
      if (response.data == null || response.data['error'] != null) {
        throw Exception(response.data?['error'] ?? 'Failed to create setup intent.');
      }

      // Extract the client_secret from the successful response and return it.
      final clientSecret = response.data['client_secret'] as String;
      return clientSecret;
    } catch (e) {
      // Rethrow the error to be handled by the ViewModel.
      rethrow;
    }
  }
}