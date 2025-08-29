// lib/main.dart

// Original comments are retained and updated.
import 'package:flutter/material.dart';
// ✅ NEW: Import the DartPluginRegistrant.
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/features/auth/presentation/views/auth_gate.dart';
import 'package:screenpledge/core/data/datasources/revenuecat_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:workmanager/workmanager.dart';
import 'package:screenpledge/core/services/background_task_handler.dart';
import 'package:screenpledge/core/services/notification_service.dart';

// The top-level callbackDispatcher and task constants.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // ✅ THE DEFINITIVE FIX: This line is the key to solving the MissingPluginException.
    // As per official Flutter guidance for background isolates, this function
    // automatically finds and initializes all the necessary plugin bindings
    // (like our MethodChannel) for this background context.
    DartPluginRegistrant.ensureInitialized();

    // The rest of the dispatcher logic remains the same.
    switch (task) {
      case dailyDataSubmissionTask:
        final handler = DailyDataSubmissionHandler();
        return await handler.submitDailyData();
      case warningNotificationTask:
        final handler = WarningNotificationHandler();
        return await handler.runWarningChecks();
      default:
        return true;
    }
  });
}

/// The main entry point for the ScreenPledge application.
void main() async {
  // --- Step 1: Ensure Flutter is ready ---
  // This must be the very first line.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Step 2: Load Environment Variables ---
  // We must load the .env file before we can use any of the keys.
  await dotenv.load(fileName: ".env");

  // --- Step 3: Initialize Services that DEPEND on .env keys ---
  // Now that dotenv is loaded, we can safely access its properties.
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Stripe
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  // --- Step 4: Initialize Services that DO NOT depend on .env keys ---

  // Initialize Notification Service
  await NotificationService.initialize();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  // --- Step 5: Register Background Tasks ---
  // This can be done after workmanager is initialized.

  // Register the periodic data submission task.
  Workmanager().registerPeriodicTask(
    "dailyDataSubmissionTask-unique",
    dailyDataSubmissionTask,
    frequency: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // Register the chained warning notification task.
  Workmanager().registerOneOffTask(
    "initialWarningTask-unique",
    warningNotificationTask,
    existingWorkPolicy: ExistingWorkPolicy.keep,
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  // --- Step 6: Initialize Final Services (like RevenueCat) ---
  final rcDataSource = RevenueCatRemoteDataSource(
    androidPublicApiKey: dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? 'YOUR_ANDROID_PUBLIC_KEY',
    iosPublicApiKey: dotenv.env['REVENUECAT_IOS_API_KEY'] ?? 'YOUR_IOS_PUBLIC_KEY',
    defaultOfferingId: 'default',
    enableDebugLogs: true,
  );
  await rcDataSource.configure();

  // --- Step 7: Run the App ---
  // This is the final step after all initializations are complete.
  runApp(
    const ProviderScope(
      child: ScreenPledgeApp(),
    ),
  );
}

// The ScreenPledgeApp widget remains unchanged.
class ScreenPledgeApp extends StatelessWidget {
  const ScreenPledgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScreenPledge',
      theme: AppTheme.themeData,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}