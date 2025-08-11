// lib/core/data/repositories/auth_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:screenpledge/core/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final SupabaseAuthRemoteDataSource _remoteDataSource;
  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  Future<User> signUpWithEmail({required String email, required String password}) async {
    // ✅ FIXED: Removed the unnecessary try-catch block for a cleaner implementation.
    // If an exception occurs in the data source, it will now propagate naturally.
    return await _remoteDataSource.signUpWithEmail(email: email, password: password);
  }

  // ✅ ADDED: Concrete implementation for signInWithEmail.
  @override
  Future<User> signInWithEmail({required String email, required String password}) async {
    // For now, we just delegate the call directly to the data source.
    // This follows the same pattern as signUp.
    // We will need to add the corresponding method to the data source next.
    return await _remoteDataSource.signInWithEmail(email: email, password: password);
  }

  // ✅ ADDED: Concrete implementation for signOut.
  @override
  Future<void> signOut() async {
    // Delegate the call to the data source.
    return await _remoteDataSource.signOut();
  }

  // ✅ ADDED: Implementation for verifyOtp.
  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    return await _remoteDataSource.verifyOtp(email: email, token: token);
  }

  // ✅ ADDED: Implementation for resendOtp.
  @override
  Future<void> resendOtp({required String email}) async {
    return await _remoteDataSource.resendOtp(email: email);
  }



}