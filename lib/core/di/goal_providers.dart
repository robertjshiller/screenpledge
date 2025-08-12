import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/datasources/goal_remote_datasource.dart';
import 'package:screenpledge/core/data/repositories/goal_repository_impl.dart';
import 'package:screenpledge/core/di/service_providers.dart'; // ✅ This import brings in the supabaseClientProvider.
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:screenpledge/core/domain/usecases/save_goal.dart';

/// Provider for the GoalRemoteDataSource.
///
/// It depends on the global Supabase client provider.
final goalRemoteDataSourceProvider = Provider<GoalRemoteDataSource>((ref) {
  // ✅ FIXED: Correctly watches the 'supabaseClientProvider' from service_providers.dart.
  final supabaseClient = ref.watch(supabaseClientProvider);
  return GoalRemoteDataSource(supabaseClient);
});

/// Provider for the GoalRepository.
///
/// This is the provider that the rest of the app will interact with.
/// It provides the abstract [IGoalRepository] type, hiding the implementation details.
final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  final remoteDataSource = ref.watch(goalRemoteDataSourceProvider);
  return GoalRepositoryImpl(remoteDataSource);
});

/// Provider for the SaveGoalUseCase.
final saveGoalUseCaseProvider = Provider<SaveGoalUseCase>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return SaveGoalUseCase(repository);
});