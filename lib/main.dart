import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  await Stripe.instance.applySettings();

  await NotificationService.initialize();

  // This is the modern, correct initialization for workmanager ^0.9.0
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().registerPeriodicTask(
    "dailyDataSubmissionTask-unique",
    dailyDataSubmissionTask,
    frequency: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  Workmanager().registerOneOffTask(
    "initialWarningTask-unique",
    warningNotificationTask,
    existingWorkPolicy: ExistingWorkPolicy.keep,
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  final rcDataSource = RevenueCatRemoteDataSource(
    androidPublicApiKey: dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? 'YOUR_ANDROID_PUBLIC_KEY',
    iosPublicApiKey: dotenv.env['REVENUECAT_IOS_API_KEY'] ?? 'YOUR_IOS_PUBLIC_KEY',
    defaultOfferingId: 'default',
    enableDebugLogs: true,
  );
  await rcDataSource.configure();

  runApp(
    const ProviderScope(
      child: ScreenPledgeApp(),
    ),
  );
}

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