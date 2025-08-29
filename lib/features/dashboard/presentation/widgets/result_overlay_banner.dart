// lib/features/dashboard/presentation/widgets/result_overlay_banner.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';

/// A banner that overlays the dashboard to show the result of the previous day.
///
/// This widget is stateful so it can manage its own visibility and an
/// auto-dismiss timer.
class ResultOverlayBanner extends StatefulWidget {
  final DailyResult result;

  const ResultOverlayBanner({super.key, required this.result});

  @override
  State<ResultOverlayBanner> createState() => _ResultOverlayBannerState();
}

class _ResultOverlayBannerState extends State<ResultOverlayBanner> {
  // A flag to control the visibility of the banner for animations.
  bool _isVisible = false;
  // A timer to automatically dismiss the banner after a set duration.
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    // When the widget is first built, wait a moment then animate it into view.
    // This brief delay allows the main dashboard UI to build first.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
        // Start the auto-dismiss timer once the banner is visible.
        _startDismissTimer();
      }
    });
  }

  @override
  void dispose() {
    // Clean up the timer when the widget is removed from the tree.
    _dismissTimer?.cancel();
    super.dispose();
  }

  /// Starts a timer that will hide the banner after 8 seconds.
  void _startDismissTimer() {
    _dismissTimer = Timer(const Duration(seconds: 8), () {
      _dismissBanner();
    });
  }

  /// Hides the banner by setting the visibility flag to false.
  void _dismissBanner() {
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Determine the content and styling based on the outcome (success or failure).
    final isSuccess = widget.result.outcome == DailyOutcome.success;

    // Define content specific to the outcome.
    final IconData icon = isSuccess ? Icons.celebration_rounded : Icons.shield_outlined;
    final String title = isSuccess ? 'SUCCESS!' : 'Accountability Enforced.';
    final String subtitle = isSuccess
        ? "Congratulations on meeting your goal yesterday! We've added [+10 Pledge Points] to your account." // TODO: Use real points
        : "Yesterday you went over your limit. As promised, your pledge has been processed."; // TODO: Use real pledge amount
    final Color backgroundColor = isSuccess ? AppColors.buttonFill.withOpacity(0.15) : Colors.red.withOpacity(0.1);
    final Color borderColor = isSuccess ? AppColors.buttonFill : Colors.red.shade400;

    // Use AnimatedPositioned to slide the banner in and out from the top.
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      top: _isVisible ? 16.0 : -200.0, // Start off-screen, slide to 16.0 from top.
      left: 16.0,
      right: 16.0,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: borderColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              // A manual dismiss button.
              InkWell(
                onTap: () {
                  _dismissTimer?.cancel(); // Stop the auto-dismiss timer.
                  _dismissBanner();
                },
                child: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}