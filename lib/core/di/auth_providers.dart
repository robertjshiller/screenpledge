// lib/core/di/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:screenpledge/core/data/repositories/auth_repository_impl.dart';
import 'package:screenpledge/core/domain/repositories/auth_repository.dart';
import 'package:screenpledge/core/domain/usecases/sign_up.dart';
import 'package:screenpledge/core/domain/usecases/verify_otp.dart'; // ✅ ADDED
import 'package:screenpledge/core/domain/usecases/resend_otp.dart'; // ✅ ADDED


// This provider gives us the Supabase client instance.
// You'll need to have initialized Supabase in your main.dart for this to work.
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

// --- DATA LAYER PROVIDERS ---
final authRemoteDataSourceProvider = Provider<SupabaseAuthRemoteDataSource>((ref) {
  return SupabaseAuthRemoteDataSource(ref.read(supabaseClientProvider));
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// --- DOMAIN LAYER PROVIDERS ---
final signUpUseCaseProvider = Provider<SignUp>((ref) {
  return SignUp(ref.read(authRepositoryProvider));
});

// Provider for the auth state stream
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ✅ ADDED: Provider for the VerifyOtp use case.
final verifyOtpUseCaseProvider = Provider<VerifyOtp>((ref) {
  return VerifyOtp(ref.read(authRepositoryProvider));
});

// ✅ ADDED: Provider for the ResendOtp use case.
final resendOtpUseCaseProvider = Provider<ResendOtp>((ref) {
  return ResendOtp(ref.read(authRepositoryProvider));
});


