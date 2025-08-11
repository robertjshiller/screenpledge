// lib/core/domain/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// The DOMAIN layer contract for handling all authentication operations.
abstract class IAuthRepository {
  /// Creates a new user with email and password.
  /// Returns the new User object on success.
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in a user with email and password.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  Future<void> signOut();


  /// A stream that emits the User object when auth state changes (login/logout).
  /// Emits null if the user is logged out.
  Stream<User?> get authStateChanges;

  // ✅ ADDED: A method to verify a sign-up OTP.
  Future<void> verifyOtp({
    required String email,
    required String token,
  });

  // ✅ ADDED: A method to resend a sign-up OTP.
  Future<void> resendOtp({
    required String email,
  });

}