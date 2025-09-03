import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screen_time_channel/installed_app.dart';
import 'package:screen_time_channel/screen_time_service.dart';

/// Use case for fetching the list of most-used applications.
class GetUsageTopApps {
  final ScreenTimeService _service;
  GetUsageTopApps(this._service);

  Future<List<InstalledApp>> call() async {
    return _service.getUsageTopApps();
  }
}

/// Riverpod provider for the GetUsageTopApps use case.
final getUsageTopAppsUseCaseProvider = Provider<GetUsageTopApps>((ref) {
  return GetUsageTopApps(ref.read(screenTimeServiceProvider));
});