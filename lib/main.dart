// lib/main.dart

// Original comments are retained.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADDED: Required for Riverpod state management.
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/features/auth/presentation/views/auth_gate.dart'; // ✅ ADDED: The new entry point.
import 'package:screenpledge/core/data/datasources/revenuecat_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ ADDED: The official Supabase Flutter SDK.
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ ADDED: The package to read .env files.
import 'package:flutter_stripe/flutter_stripe.dart'; // ✅ ADDED: The official Stripe Flutter SDK.
// ✅ NEW: Import the workmanager package.
import 'package:workmanager/workmanager.dart';
// ✅ NEW: Import our new background task handler file.
import 'package:screenpledge/core/services/background_task_handler.dart';
// ✅ NEW: Import our new notification service.
import 'package:screenpledge/core/services/notification_service.dart';

// ✅ NEW: Define the unique name for our daily data submission task.
// Using a constant helps prevent typos and makes the code easier to manage.
const dailyDataSubmissionTask = "com.screenpledge.app.dailyDataSubmissionTask";

// ✅ NEW: This is the top-level function that Workmanager will call.
// It must be defined outside of any class.
// When the OS triggers the background task, this function is the entry point.
// It then calls our more organized BackgroundTaskHandler to do the actual work.
@pragma('vm:entry-point') // Mandatory annotation for background execution
void callbackDispatcher() {
  // The `executeTask` method is where the actual logic will live.
  // It needs to be initialized here to handle the task execution.
  Workmanager().executeTask((task, inputData) async {
    // We only have one task for now, but a switch statement is good practice
    // in case we add more background tasks in the future.
    switch (task) {
      case dailyDataSubmissionTask:
        // Initialize a BackgroundTaskHandler and run the submission logic.
        final handler = BackgroundTaskHandler();
        await handler.submitDailyData();
        break;
    }
    // Return true to indicate that the task was successful.
    return Future.value(true);
  });
}


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

  // ✅ ADDED: Initialize the Stripe SDK with the publishable key from .env.
  // This must be done before any other Stripe methods are called.
  // The `!` (null-check operator) tells Dart we are certain this value exists.
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  // ✅ NEW: Initialize our NotificationService.
  // This sets up the channels and prepares the plugin for use. Must be called
  // before any notifications can be shown.
  await NotificationService.initialize();

  // ✅ NEW: Initialize the Workmanager service.
  // This tells the app to listen for background task triggers from the OS.
  // The `callbackDispatcher` is the function that will be called when a task runs.
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false for release builds. Logs task execution to console.
  );

  // ✅ NEW: Register our periodic task for daily data submission.
  // This tells the OS to run our task approximately once every 24 hours.
  // The OS will optimize for battery, so the timing is not exact.
  // `existingWorkPolicy: ExistingWorkPolicy.keep` ensures that if a task is
  // already scheduled, we don't accidentally create a duplicate one on app restart.
  Workmanager().registerPeriodicTask(
    "dailyDataSubmissionTask-1", // A unique name for the registration.
    dailyDataSubmissionTask,     // The name of the task itself.
    frequency: const Duration(days: 1),
    existingWorkPolicy: ExistingWorkPolicy.keep,
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