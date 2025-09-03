import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screen_time_channel/screen_time_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A use case that checks if the usage permission has been granted.
///
/// This is the "re-check" part of the "fire and re-check" strategy.
class IsScreenTimePermissionGranted {
  final ScreenTimeService _service;
  IsScreenTimePermissionGranted(this._service);

  Future<bool> call() async {
    return await _service.isPermissionGranted();
  }
}

/// The Riverpod provider for the IsScreenTimePermissionGranted use case.
final isPermissionGrantedUseCaseProvider = Provider<IsScreenTimePermissionGranted>((ref) {
  return IsScreenTimePermissionGranted(ref.read(screenTimeServiceProvider));
});