
// lib/core/data/datasources/user_remote_data_source.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// The data source responsible for all direct communication with the remote
/// 'profiles' table in Supabase.
///
/// This class handles fetching and updating user profile data.
class UserRemoteDataSource {
  final SupabaseClient _supabase;

  UserRemoteDataSource(this._supabase);

  /// Fetches a user profile from the 'profiles' table based on the user's ID.
  ///
  /// The `userId` must correspond to the `id` of the user in `auth.users`.
  /// Returns the raw JSON map of the profile.
  /// Throws a [PostgrestException] if the user is not found or if there's a
  /// database error.
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      // Use .select() to get all columns, .eq() to filter by the 'id' column,
      // and .single() to ensure only one row is returned. If no user or multiple
      // users are found, Supabase will throw an error, which is what we want.
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      // Re-throw the exception to be handled by the repository layer, which
      // might want to log it or convert it to a domain-specific error.
      rethrow;
    }
  }

  // Future<void> updateProfile(Map<String, dynamic> profileData) async { ... }
}
