// lib/core/di/service_providers.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/domain/usecases/request_screen_time_permission.dart';
import 'package:screenpledge/core/services/android_screen_time_service.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// A Riverpod provider that determines which concrete implementation of
/// [ScreenTimeService] to use based on the current operating system.
final screenTimeServiceProvider = Provider<ScreenTimeService>((ref) {
  if (Platform.isAndroid) {
    // If the app is running on Android, provide the Android implementation.
    return AndroidScreenTimeService();
  }
  // } else if (Platform.isIOS) {
  //   // TODO: When ready, provide the iOS implementation here.
  //   return IosScreenTimeService();
  // }
  else {
    // If the platform is not supported, throw an error to fail fast.
    throw UnimplementedError('ScreenTimeService is not implemented for this platform.');
  }
});

/// Provides the [RequestScreenTimePermission] use case to the UI layer.
/// It depends on the core [screenTimeServiceProvider].
final requestPermissionUseCaseProvider = Provider<RequestScreenTimePermission>((ref) {
  return RequestScreenTimePermission(ref.read(screenTimeServiceProvider));
});