import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screen_time_channel/installed_app.dart';
import 'package:screen_time_channel/screen_time_service.dart';

/// Use case for fetching the list of all installed applications.
class GetInstalledApps {
  final ScreenTimeService _service;
  GetInstalledApps(this._service);

  Future<List<InstalledApp>> call() async {
    return _service.getInstalledApps();
  }
}

/// Riverpod provider for the GetInstalledApps use case.
final getInstalledAppsUseCaseProvider = Provider<GetInstalledApps>((ref) {
  return GetInstalledApps(ref.read(screenTimeServiceProvider));
});