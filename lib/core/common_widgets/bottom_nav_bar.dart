
// lib/core/common_widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// A custom bottom navigation bar for the ScreenPledge app.
///
/// This widget provides consistent navigation across the main features of the app:
/// Dashboard, Rewards, and Settings.
///
/// It requires a [currentIndex] to highlight the active tab and an
/// [onTap] callback to handle navigation when a tab is selected.
///
/// The styling uses the app's theme colors and the specified
/// "Open Sans Condensed" font for the labels.
///
/// Example:
/// ```dart
/// Scaffold(
///   body: _pages[_selectedIndex],
///   bottomNavigationBar: BottomNavBar(
///     currentIndex: _selectedIndex,
///     onTap: (index) {
///       setState(() {
///         _selectedIndex = index;
///       });
///     },
///   ),
/// )
/// ```
class BottomNavBar extends StatelessWidget {
  /// The index of the currently active tab.
  final int currentIndex;

  /// The callback function that is executed when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Creates a custom bottom navigation bar.
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      // Use the app's background color for the navigation bar.
      backgroundColor: AppColors.background,
      // Set the color for the active icon and label.
      selectedItemColor: AppColors.primaryText,
      // Set the color for inactive icons and labels.
      unselectedItemColor: AppColors.primaryText.withOpacity(0.6),
      // Use the specified font for the labels.
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Open Sans Condensed',
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Open Sans Condensed',
        fontWeight: FontWeight.bold,
      ),
      // Remove the default elevation for a flat design.
      elevation: 0,
      // Define the navigation items.
      items: [
        _buildNavItem(
          iconPath: 'assets/icons/dashboard.svg',
          label: 'Dashboard',
        ),
        _buildNavItem(
          iconPath: 'assets/icons/rewards.svg',
          label: 'Rewards',
        ),
        _buildNavItem(
          iconPath: 'assets/icons/settings.svg',
          label: 'Settings',
        ),
      ],
    );
  }

  /// A helper method to build a single [BottomNavigationBarItem].
  BottomNavigationBarItem _buildNavItem({
    required String iconPath,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        iconPath,
        // Use the unselected color by default.
        colorFilter: ColorFilter.mode(
          AppColors.inactive,
          BlendMode.srcIn,
        ),
      ),
      activeIcon: SvgPicture.asset(
        iconPath,
        // Use the selected color for the active icon.
        colorFilter: const ColorFilter.mode(
          AppColors.primaryText,
          BlendMode.srcIn,
        ),
      ),
      label: label,
    );
  }
}
