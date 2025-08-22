
// lib/core/config/theme/app_colors.dart

import 'package:flutter/material.dart';

/// A utility class that holds all the color constants for the ScreenPledge app.
///
/// This approach centralizes color definitions, making it easy to manage and update
/// the application's color palette from a single source of truth. It prevents
/// hard-coded color values from scattering across the UI code, promoting
/// consistency and maintainability.
///
/// Example:
/// ```dart
/// Container(
///   color: AppColors.background,
///   child: Text(
///     'Hello World',
///     style: TextStyle(color: AppColors.primaryText),
///   ),
/// )
/// ```
class AppColors {
  // This private constructor prevents the class from being instantiated.
  // All members should be static constants.
  AppColors._();

  // --- PRIMARY PALETTE ---

  /// The primary background color for the application.
  ///
  /// Used for screen backgrounds, card backgrounds, and other large surfaces.
  /// Hex: #DEFDD4
  static const Color background = Color(0xFFDEFDD4);

  /// The primary text color used for headlines, body text, and important labels.
  ///
  /// This color is designed to have strong contrast against the `background` color
  /// to ensure readability.
  /// Hex: #222222
  static const Color primaryText = Color(0xFF222222);

  /// The secondary text color, for less prominent information.
  /// Hex: #484848
  static const Color secondaryText = Color(0xFF484848);

  // --- Accent & Semantic Colors (Placeholders) ---
  // These can be expanded as the app grows.

  /// The primary fill color for interactive elements like buttons.
  /// Hex: #16DA9C
  static const Color buttonFill = Color(0xFF16DA9C);

  /// The text color for primary buttons.
  /// Hex: #FDFDFD
  static const Color buttonText = Color(0xFFFDFDFD);

  /// The stroke color used for the border of interactive elements like buttons.
  /// Hex: #009966
  static const Color buttonStroke = Color(0xFF009966);

  /// A bright, attention-grabbing color for highlighting active states or key info.
  /// Hex: #00FF00
  static const Color primaryAccent = Color(0xFF00FF00);

  /// The starting color for the vibrant green gradient.
  /// Hex: #16DA9C
  static const Color gradientGreenStart = Color(0xFF16DA9C);

  /// The ending color for the vibrant green gradient.
  /// Hex: #009966
  static const Color gradientGreenEnd = Color(0xFF009966);

  /// The color for inactive icons or text, providing a subtle, muted look.
  /// This is the primary text color with 60% opacity.
  static const Color inactive = Color(0x99222222); // 255 * 0.6 = 153 (0x99)
}
