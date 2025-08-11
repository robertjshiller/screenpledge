import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/domain/usecases/request_screen_time_permission.dart';

/// Manages the state and business logic for the PermissionPage.
/// ✅ CHANGED: This ViewModel's role is now simpler. It is only responsible for
/// initiating the action of opening the settings screen. It no longer tries to
/// fetch or return the permission status itself.
class PermissionViewModel extends StateNotifier<AsyncValue<void>> {
  final RequestScreenTimePermission _requestPermissionUseCase;

  PermissionViewModel(this._requestPermissionUseCase) : super(const AsyncValue.data(null));

  /// ✅ RENAMED & REWORKED: This method now simply opens the settings screen.
  ///
  /// It sets a loading state for the brief moment it takes to launch the
  /// native settings activity. It does not return a result.
  Future<void> openSettings() async {
    // Set the state to loading to show an indicator in the UI (e.g., "Opening Settings...").
    state = const AsyncValue.loading();
    try {
      // Call the use case. This will complete as soon as settings are open.
      await _requestPermissionUseCase();
      // Once the call is complete, set the state back to idle.
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // If any unexpected error occurs, capture it and set the state.
      state = AsyncValue.error(e, st);
    }
  }
}

/// The Riverpod provider for the PermissionViewModel.
final permissionViewModelProvider =
    StateNotifierProvider.autoDispose<PermissionViewModel, AsyncValue<void>>(
  (ref) {
    // The ViewModel depends on the use case, which is provided from our core DI file.
    return PermissionViewModel(ref.read(requestPermissionUseCaseProvider));
  },
);