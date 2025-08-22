// lib/core/data/repositories/profile_repository_impl.dart

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
      final profile = Profile.fromJson(rawProfileData);
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
}
