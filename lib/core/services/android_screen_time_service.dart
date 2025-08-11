import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// The concrete Android implementation of the [ScreenTimeService].
///
/// This class uses a [MethodChannel] to communicate with the native Kotlin
/// code in `MainActivity.kt`. It now follows the "fire and re-check" pattern.
class AndroidScreenTimeService implements ScreenTimeService {
  // The channel name must match exactly the one defined in MainActivity.kt.
  static const _channel = MethodChannel('com.screenpledge.app/screentime');

  // ✅ CHANGED: This method now correctly implements the new contract by returning Future<void>.
  // It invokes the native method to open the settings screen and does not await any
  // permission status in return. It's a "fire and forget" operation.
  @override
  Future<void> requestPermission() async {
    try {
      // This invokes the "requestPermission" method on the Kotlin side.
      // The native code will open settings and the Future will complete immediately
      // without waiting for the user to return.
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      // Even though we don't expect a result, we still catch potential errors
      // in case the method channel call itself fails.
      debugPrint("Failed to open usage settings: '${e.message}'.");
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    try {
      // This method remains the same, calling our reliable "verify by action" check
      // on the native side.
      return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission status: '${e.message}'.");
      return false;
    }
  }
}