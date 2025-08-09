import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// A utility class that provides the master [ThemeData] for the ScreenPledge app.
///
/// This class centralizes the application's visual styling, ensuring a consistent
/// look and feel across all screens. It leverages the color constants defined in
/// [AppColors] to build a cohesive theme.
///
/// By defining text styles, color schemes, and component themes here, we can
/// make global UI changes efficiently and avoid style duplication.
///
/// The theme is accessed via the static `themeData` getter.
///
/// Example:
/// ```dart
/// MaterialApp(
///   title: 'ScreenPledge',
///   theme: AppTheme.themeData,
///   home: const GetStartedPage(),
/// );
/// ```
class AppTheme {
  // This private constructor prevents the class from being instantiated.
  AppTheme._();

  /// For extra large, impactful text like statistics
  static const TextStyle displayExtraLarge = TextStyle(
    fontFamily: 'Open Sans',
    fontSize: 60.0,
    fontWeight: FontWeight.w800, // Extra Bold
    color: AppColors.primaryText, // Fallback color, gradient will be applied on top
  );

  /// The main [ThemeData] for the application.
  static final ThemeData themeData = ThemeData(
    // --- FONT FAMILY ---
    // Set the default font family for the entire application.
    // Specific text styles can override this, but it provides a consistent base.
    // Note: You must add the Nunito font files to your project and declare
    // them in `pubspec.yaml` for this to work.
    fontFamily: 'Open Sans',

    // --- CORE COLORS ---
    // Define the primary color scheme of the app.
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.background, // Often used for app bars, etc.
    colorScheme: const ColorScheme.light(
      primary: AppColors.background, // Primary interactive color
      secondary: AppColors.primaryText, // Secondary interactive color
      background: AppColors.background, // Screen background color
      surface: AppColors.background, // Card and dialog background color
      onPrimary: AppColors.primaryText, // Text/icon color on primary color
      onSecondary: AppColors.background, // Text/icon color on secondary color
      onBackground: AppColors.primaryText, // Text/icon color on background
      onSurface: AppColors.primaryText, // Text/icon color on surface
      error: Colors.red, // A default error color
      onError: Colors.white, // Text/icon color on error color
    ),

    // --- TYPOGRAPHY ---
    // Define the default text styling for the entire application.
    // We use 'Open Sans' as the base font family. Headers are bold, body text is regular.
    textTheme: const TextTheme(
      // For major headlines
      displayLarge: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 32.0,
        fontWeight: FontWeight.w800, // Header = Extra Bold
        color: AppColors.primaryText,
      ),

      // For standard-sized headlines
      headlineMedium: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 24.0,
        fontWeight: FontWeight.bold, // Header = Bold
        color: AppColors.primaryText,
      ),
      // For smaller headlines, often used for subheadings or important labels
      headlineSmall: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 20.0,
        fontWeight: FontWeight.bold, // Header = Bold
        color: AppColors.primaryText,
      ),
      // For body text, descriptions, and general content
      bodyLarge: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 18.0,
        fontWeight: FontWeight.normal, // Body = Regular
        color: AppColors.primaryText,
      ),
      // For smaller body text or labels
      bodyMedium: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 14.0,
        fontWeight: FontWeight.normal, // Body = Regular
        color: AppColors.primaryText,
      ),
      // For buttons and other interactive text
      labelLarge: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 16.0,
        fontWeight: FontWeight.bold, // Button Text = Bold
        color: AppColors.primaryText,
      ),
      // For small, de-emphasized text or captions
      labelSmall: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 8.0,
        fontWeight: FontWeight.w300, // Light
        fontStyle: FontStyle.italic,
        color: AppColors.secondaryText,
      ),
    ).copyWith(
      // For very small, subtle text, often used for disclaimers or captions.
      bodySmall: const TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 12.0,
        fontWeight: FontWeight.w300, // Light weight
        fontStyle: FontStyle.normal, // Normal style
        color: AppColors.primaryText,
      ),
    ),

    // --- COMPONENT THEMES ---
    // Define default styles for common widgets to ensure consistency.

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0, // No shadow for a flat, modern look
      iconTheme: IconThemeData(color: AppColors.primaryText),
      titleTextStyle: TextStyle(
        fontFamily: 'Open Sans',
        fontSize: 20.0,
        fontWeight: FontWeight.bold, // AppBar Title = Bold
        color: AppColors.primaryText,
      ),
    ),

    // ElevatedButton Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.buttonText, // Text color on the button
        backgroundColor: AppColors.buttonFill, // Button background color
        textStyle: const TextStyle(
          fontFamily: 'Open Sans',
          fontSize: 16,
          fontWeight: FontWeight.bold, // Button Text = Bold
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(
            color: AppColors.buttonStroke, // The "stroke" color
            width: 2.0, // The width of the border
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      ),
    ),

    // InputField (TextFormField) Theme
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Assuming a white input field on the colored background
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide.none, // No border for a cleaner look
      ),
      hintStyle: TextStyle(
        color: Colors.grey, // Placeholder text color
        fontFamily: 'Open Sans',
        fontWeight: FontWeight.normal, // Hint Text = Regular
      ),
    ),
  );
}