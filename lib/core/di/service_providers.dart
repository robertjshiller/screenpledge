import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/services/android_screen_time_service.dart';
import 'package:screen_time_channel/screen_time_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// A core provider for the Supabase client instance.
///
/// This makes the Supabase client available to the rest of the app via Riverpod's
/// dependency injection system. It's better than accessing the global singleton
/// `Supabase.instance.client` everywhere, as it makes dependencies explicit.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});