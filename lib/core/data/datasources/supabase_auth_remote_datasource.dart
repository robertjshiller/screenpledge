// lib/core/data/datasources/supabase_auth_remote_datasource.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRemoteDataSource {
  final SupabaseClient _client;
  SupabaseAuthRemoteDataSource(this._client);

  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    if (response.user == null) {
      throw const AuthException('Sign up failed: User is null.');
    }
    return response.user!;
  }

  // ✅ ADDED: Method to handle sign-in via the Supabase SDK.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    if (response.user == null) {
      throw const AuthException('Sign in failed: User is null.');
    }
    return response.user!;
  }

  // ✅ ADDED: Method to handle sign-out via the Supabase SDK.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<User?> get authStateChanges => _client.auth.onAuthStateChange.map((event) => event.session?.user);

  // ✅ ADDED: The method that calls the Supabase SDK to verify the OTP.
  // The `type` is critical - it tells Supabase this is for a new user sign-up.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: token,
    );
  }

  // ✅ ADDED: The method that calls the Supabase SDK to resend the OTP.
  Future<void> resendOtp({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }


}