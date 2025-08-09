import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/config/theme/app_theme.dart';
import 'package:screenpledge/core/common_widgets/bottom_nav_bar.dart';

/// A page displayed on Day 1 when a user has set a goal and pledge,
/// but the pledge is pending activation (i.e., waiting for the next midnight).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0; // Default to Dashboard

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Implement navigation logic based on index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ), // AppBar
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/mascot/mascot_neutral.png', // Neutral mascot for general dashboard
                height: 150,
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to your Dashboard!',
                style: AppTheme.themeData.textTheme.displayLarge?.copyWith(
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "This is where you'll track your progress and manage your pledges.",
                style: AppTheme.themeData.textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Placeholder for future dashboard content or actions
              // Removed the "Back to Dashboard" button as it's no longer relevant.
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
