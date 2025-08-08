// lib/main.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/get_started_page.dart';

/// The main entry point for the ScreenPledge application.
///
/// This function is called when the app is launched. Its primary responsibility
/// is to initialize any necessary services (though none are needed yet) and
/// to run the root widget of the application, [ScreenPledgeApp].
void main() {
  // runApp() inflates the given widget and attaches it to the screen.
  runApp(const ScreenPledgeApp());
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
  /// state preservation during rebuilds.
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

      // The home property defines the default screen (or "route") of the app.
      // By setting this to `GetStartedPage`, we ensure that all users will
      // land on this screen when they first open the app.
      home: const GetStartedPage(),

      // This removes the "debug" banner from the top-right corner of the app.
      debugShowCheckedModeBanner: false,
    );
  }
}