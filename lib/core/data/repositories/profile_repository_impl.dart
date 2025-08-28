// lib/core/data/repositories/profile_repository_impl.dart

// Original comments are retained.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/data/datasources/user_remote_data_source.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';

/// This is the concrete implementation of the [IProfileRepository] contract.
class ProfileRepositoryImpl implements IProfileRepository {
  final UserRemoteDataSource _remoteDataSource;
  final SupabaseClient _supabaseClient;

  ProfileRepositoryImpl(this._remoteDataSource, this._supabaseClient);

  /// Fetches the profile for the currently authenticated user.
  @override
  Future<Profile> getMyProfile() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('No authenticated user found.');
      }
      final rawProfileData = await _remoteDataSource.getProfile(userId);
      // ✅ FIX: Changed the method call from Profile.fromJson() to Profile.fromMap().
      // This aligns with the updated Profile entity, which now uses fromMap() to
      // deserialize data from a Map (like the one we get from Supabase) and
      // reserves fromJson() for deserializing from a raw JSON string.
      final profile = Profile.fromMap(rawProfileData);
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ ADDED: The concrete implementation for saving the draft goal via an RPC.
  @override
  Future<void> saveOnboardingDraftGoal(Map<String, dynamic> draftGoal) async {
    try {
      // This calls our new RPC, passing the draft goal data.
      // The server-side function handles the atomic update.
      await _supabaseClient.rpc(
        'save_onboarding_goal_draft',
        params: {'draft_goal_data': draftGoal},
      );
    } catch (e) {
      rethrow;
    }
  }

  // ✅ NEW: The concrete implementation for creating the Stripe Setup Intent.
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