import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screen_time_channel/screen_time_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A use case that opens the system settings screen for usage permission.
///
/// ✅ CHANGED: This now follows the "fire and forget" pattern. It returns a
/// Future<void> and completes as soon as the settings screen is launched.
class RequestScreenTimePermission {
  final ScreenTimeService _service;
  RequestScreenTimePermission(this._service);

  Future<void> call() async {
    return await _service.requestPermission();
  }
}

/// The Riverpod provider for the RequestScreenTimePermission use case.
final requestPermissionUseCaseProvider = Provider<RequestScreenTimePermission>((ref) {
  return RequestScreenTimePermission(ref.read(screenTimeServiceProvider));
});