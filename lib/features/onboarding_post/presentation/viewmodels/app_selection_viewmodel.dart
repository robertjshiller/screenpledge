import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/domain/usecases/get_installed_apps.dart';
import 'package:screenpledge/core/domain/usecases/get_usage_top_apps.dart';

// Represents the combined data needed for the AppSelectionPage.
class AppSelectionData {
  final List<InstalledApp> suggestedApps;
  final List<InstalledApp> allApps;
  AppSelectionData({required this.suggestedApps, required this.allApps});
}

// The state managed by our ViewModel.
class AppSelectionState {
  // The core data, wrapped in AsyncValue to handle loading/error states.
  final AsyncValue<AppSelectionData> data;
  // The set of currently selected apps. Using a Set is efficient for lookups.
  final Set<InstalledApp> selectedApps;
  // The current search query entered by the user.
  final String searchQuery;

  AppSelectionState({
    this.data = const AsyncValue.loading(),
    this.selectedApps = const {},
    this.searchQuery = '',
  });

  // Helper method to create a copy of the state with new values.
  AppSelectionState copyWith({
    AsyncValue<AppSelectionData>? data,
    Set<InstalledApp>? selectedApps,
    String? searchQuery,
  }) {
    return AppSelectionState(
      data: data ?? this.data,
      selectedApps: selectedApps ?? this.selectedApps,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Manages the state and logic for the AppSelectionPage.
class AppSelectionViewModel extends StateNotifier<AppSelectionState> {
  final GetInstalledApps _getInstalledApps;
  final GetUsageTopApps _getUsageTopApps;

  AppSelectionViewModel(
    this._getInstalledApps,
    this._getUsageTopApps,
    Set<InstalledApp> initialSelection,
  ) : super(AppSelectionState(selectedApps: initialSelection)) {
    // Fetch the data as soon as the ViewModel is created.
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    state = state.copyWith(data: const AsyncValue.loading());
    try {
      // Fetch both lists in parallel for better performance.
      final results = await Future.wait([
        _getUsageTopApps(),
        _getInstalledApps(),
      ]);
      final appData = AppSelectionData(
        suggestedApps: results[0],
        allApps: results[1],
      );
      state = state.copyWith(data: AsyncValue.data(appData));
    } catch (e, st) {
      state = state.copyWith(data: AsyncValue.error(e, st));
    }
  }

  /// Toggles the selection status of a single app.
  void toggleAppSelection(InstalledApp app) {
    final newSelection = Set<InstalledApp>.from(state.selectedApps);
    if (newSelection.contains(app)) {
      newSelection.remove(app);
    } else {
      newSelection.add(app);
    }
    state = state.copyWith(selectedApps: newSelection);
  }

  /// Updates the search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// The Riverpod provider for the AppSelectionViewModel.
///
/// We use .autoDispose and .family to pass in the initial selection.
final appSelectionViewModelProvider = StateNotifierProvider.autoDispose
    .family<AppSelectionViewModel, AppSelectionState, Set<InstalledApp>>(
  (ref, initialSelection) {
    return AppSelectionViewModel(
      ref.watch(getInstalledAppsUseCaseProvider),
      ref.watch(getUsageTopAppsUseCaseProvider),
      initialSelection,
    );
  },
);