import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Represents a single application installed on the user's device.
///
/// This is a pure data class (Entity) used across the app, so it lives in the core domain layer.
@immutable
class InstalledApp {
  /// The user-facing name of the application (e.g., "Instagram").
  final String name;

  /// The unique identifier for the application (e.g., "com.instagram.android").
  final String packageName;

  /// The raw byte data for the application's icon.
  final Uint8List icon;

  const InstalledApp({
    required this.name,
    required this.packageName,
    required this.icon,
  });

  /// ✅ ADDED: A method to convert the object into a JSON map.
  ///
  /// This is used when saving the goal to Supabase. We only store the essential
  /// identifiers, not the heavy icon data, in the 'goals' table.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
    };
  }

  // Override equality and hashCode for proper functioning in lists and sets.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstalledApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}