// lib/features/onboarding_post/data/datasources/user_survey_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// The DATA layer class responsible for making the actual database call to Supabase.
class UserSurveyRemoteDataSource {
  final SupabaseClient _client;
  UserSurveyRemoteDataSource(this._client);

  /// Inserts the survey answers into the `user_surveys` table.
  Future<void> saveSurvey(List<String?> answers) async {
    // Get the current user's ID. This is secure because it's from the active session.
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('User is not authenticated.');
    }

    // Map the list of answers to the corresponding database columns.
    // This mapping must match the order of questions in the UI.
    final surveyData = {
      'user_id': userId,
      'age_range': answers[0],
      'occupation': answers[1],        // Corresponds to "primary_role" in the UI
      'primary_purpose': answers[2],   // Corresponds to "primary_goal" in the UI
      'attribution_source': answers[3],
    };

    // The `insert` call is protected by Row Level Security (RLS) policies
    // defined in the Supabase dashboard, ensuring a user can only insert
    // a row for their own user_id.
    await _client.from('user_surveys').insert(surveyData);
  }
}