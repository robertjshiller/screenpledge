// lib/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// The DATA layer class responsible for making the actual database call to Supabase.
class UserSurveyRemoteDataSource {
  final SupabaseClient _client;
  UserSurveyRemoteDataSource(this._client);

  /// ✅ CHANGED: This method now calls the 'submit_user_survey' RPC.
  /// It passes the survey answers as a single JSON object.
  Future<void> submitSurvey(Map<String, String?> answers) async {
    // The RPC function on the backend will handle getting the user ID
    // and performing the two database operations (insert and update) atomically.
    await _client.rpc('submit_user_survey', params: {'survey_data': answers});
  }
}
