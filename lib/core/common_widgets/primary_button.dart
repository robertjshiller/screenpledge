
// lib/core/common_widgets/primary_button.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// A reusable primary button component for the ScreenPledge app.
///
/// This button is styled consistently with the application's design system,
/// but provides specific overrides for corner radius and text style as per
/// its design requirements. It is the standard call-to-action button
/// to be used across the app.
///
/// It takes a required [text] to display and an optional [onPressed] callback.
/// If [onPressed] is null, the button will be disabled.
///
/// Example:
/// ```dart
/// PrimaryButton(
///   text: 'Get Started',
///   onPressed: () {
///     print('Button tapped!');
///   },
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  /// The text to display inside the button.
  final String text;

  /// The callback that is executed when the button is pressed.
  /// If null, the button will be displayed in a disabled state.
  final VoidCallback? onPressed;

  /// Creates a primary button.
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // The style is derived from the global ElevatedButtonTheme but with specific overrides.
      style: ElevatedButton.styleFrom(
        // Use the dedicated button fill color from our theme.
        backgroundColor: AppColors.buttonFill,
        // Use pure white for the button's label, as requested.
        foregroundColor: AppColors.buttonText, // Hex: #FDFDFD
        // Set the corner radius to 5, overriding the theme's default.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          // Use the dedicated button stroke color from our theme.
          side: const BorderSide(
            color: AppColors.buttonStroke,
            width: 2.0,
          ),
        ),
        // Define the specific text style for this button, as requested.
        textStyle: const TextStyle(
          fontFamily: 'Open Sans',      // Use the header font family.
          fontWeight: FontWeight.bold, // Use the bold weight.
          fontSize: 22,              // Use the specified 22pt font size.
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
