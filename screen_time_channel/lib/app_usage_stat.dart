// lib/core/domain/entities/app_usage_stat.dart

import 'package:flutter/foundation.dart';
import 'installed_app.dart';

/// A pure domain entity that pairs an [InstalledApp] with its usage duration.
/// This is used to display the detailed breakdown on the dashboard.
@immutable
class AppUsageStat {
  /// The application's identity (name, icon, package name).
  final InstalledApp app;
  /// The amount of time the app was used.
  final Duration usage;

  const AppUsageStat({
    required this.app,
    required this.usage,
  });
}