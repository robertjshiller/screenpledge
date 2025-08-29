// lib/core/domain/repositories/profile_repository.dart

// Original comments are retained.
import 'package:screenpledge/core/domain/entities/profile.dart';

/// The contract (interface) for a repository that handles Profile-related data operations.
///
/// ✅ REFACTORED: This repository is now the single source of truth for the user's profile.
/// It is responsible for fetching data from the network, saving it to the cache,
/// and retrieving it from the cache, providing a seamless offline-first experience.
abstract class IProfileRepository {
  /// Fetches the profile for the currently authenticated user.
  ///
  /// This method implements the "Sync on Resume" pattern:
  /// 1. It will first attempt to return data from the local cache for an instant UI.
  /// 2. It will then trigger a background fetch from the remote server.
  /// 3. If the remote fetch is successful, it will update the cache with the fresh data.
  ///
  /// [forceRefresh]: If true, it will bypass the cache and fetch directly from the network.
  ///
  /// Returns a [Profile] object.
  /// Throws an exception if the operation fails and no profile is cached.
  Future<Profile> getMyProfile({bool forceRefresh = false});

  /// A dedicated method to save the draft goal and update the flag via an RPC.
  Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal);

  /// A method to call the backend function that creates a Stripe Setup Intent.
  /// It returns the client_secret required by the Stripe SDK on the frontend.
  Future<String> createStripeSetupIntent();
}