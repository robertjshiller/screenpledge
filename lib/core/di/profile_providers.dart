// lib/core/di/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/datasources/user_remote_data_source.dart';
import 'package:screenpledge/core/data/repositories/profile_repository_impl.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
// ✅ ADDED: Import for the new use case.
import 'package:screenpledge/core/domain/usecases/save_goal_and_continue.dart';

/// This file contains all the Riverpod providers related to the user Profile.

// --- DATA LAYER ---
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return UserRemoteDataSource(supabaseClient);
});

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  return ProfileRepositoryImpl(remoteDataSource, supabaseClient);
});

// --- DOMAIN LAYER ---

/// ✅ ADDED: Provider for the new SaveGoalAndContinueUseCase.
final saveGoalAndContinueUseCaseProvider = Provider<SaveGoalAndContinueUseCase>((ref) {
  final profileRepository = ref.watch(profileRepositoryProvider);
  return SaveGoalAndContinueUseCase(profileRepository);
});

// --- PRESENTATION LAYER (or for UI consumption) ---
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  if (authState is! AsyncData || authState.value == null) {
    return null;
  }
  final profileRepository = ref.watch(profileRepositoryProvider);
  return await profileRepository.getMyProfile();
});
