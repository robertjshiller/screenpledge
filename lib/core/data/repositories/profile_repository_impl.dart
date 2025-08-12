import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/data/datasources/user_remote_data_source.dart'; // Assuming this is your ProfileDataSource
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
    // ... (existing getMyProfile implementation)
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

  /// ✅ ADDED: The concrete implementation for updating the onboarding status.
  @override
  Future<void> updateOnboardingStatus(String column, bool value) async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('User is not authenticated.');
      }

      // Perform an update on the 'profiles' table for the current user.
      // The RLS policy "Users can update their own profile" allows this.
      await _supabaseClient
          .from('profiles')
          .update({column: value})
          .eq('id', userId);
          
    } catch (e) {
      // In a real app, you might want to log this error to a service.
      rethrow;
    }
  }
}