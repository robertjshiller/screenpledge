// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADDED: Required for Riverpod state management.
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/features/auth/presentation/views/auth_gate.dart'; // ✅ ADDED: The new entry point.
import 'package:screenpledge/core/data/datasources/revenuecat_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ ADDED: The official Supabase Flutter SDK.
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ ADDED: The package to read .env files.

/// The main entry point for the ScreenPledge application.
///
/// This function is called when the app is launched. Its primary responsibility
/// is to initialize any necessary core services (like Supabase and RevenueCat) and
/// to run the root widget of the application, [ScreenPledgeApp].
void main() async {
  // ✅ NEW: Ensure Flutter engine bindings are initialized BEFORE any async setup.
  // This is required if we perform asynchronous initialization (like dotenv or Supabase)
  // prior to calling runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADDED: Load environment variables from the .env file into memory.
  // This must be done before trying to access any of the variables.
  await dotenv.load(fileName: ".env");

  // ✅ UPDATED: Initialize Supabase for authentication and database access.
  // This must be called once at startup. It now uses the keys loaded from the
  // .env file, which is more secure and standard practice.
  // The `!` (null-check operator) tells Dart we are certain these values exist in our .env file.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // ✅ NEW: Initialize RevenueCat as EARLY as possible in the app lifecycle.
  // Why here?
  // - We want the SDK ready before any screen tries to fetch offerings or customer info.
  // - We start anonymous (no appUserID). After account creation we’ll call logIn(uid).
  //
  // Keys:
  // - These are PUBLIC SDK keys (NOT secret). Get them from the RevenueCat dashboard.
  // - We now load these from the .env file for consistency with Supabase keys.
  final rcDataSource = RevenueCatRemoteDataSource(
    androidPublicApiKey: dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? 'YOUR_ANDROID_PUBLIC_KEY',
    iosPublicApiKey: dotenv.env['REVENUECAT_IOS_API_KEY'] ?? 'YOUR_IOS_PUBLIC_KEY',
    // Optional: change if your canonical offering identifier isn’t "default"
    defaultOfferingId: 'default',
    enableDebugLogs: true, // turn off for production
  );

  // Idempotent configure: safe to call once at startup.
  // Note: Without App Store / Play wiring, offerings may be empty (that’s OK for now).
  await rcDataSource.configure();

  // TODO (post-signup): When the user creates an account, call:
  // await rcDataSource.logIn(appUserId);
  // and then link RC App User ID with your Supabase profile via an Edge Function.

  // ✅ runApp() inflates the given widget and attaches it to the screen.
  // We wrap the entire app in a `ProviderScope` which is the root widget
  // that makes Riverpod providers available to the entire widget tree.
  runApp(
    const ProviderScope(
      child: ScreenPledgeApp(),
    ),
  );
}

/// The root widget of the ScreenPledge application.
///
/// This widget is a [StatelessWidget] because, at this top level, it doesn't
/// manage any mutable state itself. Its primary role is to set up the
/// [MaterialApp], which defines the app's core structure, theme, and
/// initial route.
class ScreenPledgeApp extends StatelessWidget {
  /// Creates the root application widget.
  /// The `super.key` is passed to the parent constructor to uniquely identify
  /// this widget in the widget tree, which is important for performance and
  // state preservation during rebuilds.
  const ScreenPledgeApp({super.key});

  // The build method describes the part of the user interface represented by this widget.
  // Flutter calls this method when this widget is inserted into the tree and when
  // its dependencies change.
  @override
  Widget build(BuildContext context) {
    // MaterialApp is a convenience widget that wraps a number of widgets
    // that are commonly required for applications implementing Material Design.
    return MaterialApp(
      // The title is a one-line description used by the device to identify the app.
      title: 'ScreenPledge',

      // The theme property defines the overall visual styling of the application.
      // We are providing our custom theme, defined in `AppTheme.themeData`,
      // to ensure a consistent look and feel across all screens.
      theme: AppTheme.themeData,

      // The home property now points to the AuthGate.
      // The AuthGate will handle the logic to decide which screen to show
      // based on the user's authentication and onboarding status.
      home: const AuthGate(),

      // This removes the "debug" banner from the top-right corner of the app.
      debugShowCheckedModeBanner: false,
    );
  }
}