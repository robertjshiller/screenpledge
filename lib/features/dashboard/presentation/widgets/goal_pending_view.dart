// lib/features/dashboard/presentation/widgets/goal_pending_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';

/// The view for SCENARIO 1: A goal is set but not yet active.
class GoalPendingView extends StatefulWidget {
  final Goal goal;
  const GoalPendingView({super.key, required this.goal});

  @override
  State<GoalPendingView> createState() => _GoalPendingViewState();
}

class _GoalPendingViewState extends State<GoalPendingView> {
  Timer? _timer;
  Duration _timeUntilStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilStart();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeUntilStart();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeUntilStart() {
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final difference = nextDay.difference(now);
    if (mounted) {
      setState(() {
        _timeUntilStart = difference;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascot visual
            Image.asset('assets/mascot/mascot_celebrate.png', height: 120), // Placeholder
            const SizedBox(height: 24),
            // Main headline
            Text("You're All Set for Tomorrow!", style: textTheme.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Body text
            Text(
              'Your new goal is ready to go. Your first day of accountability begins at midnight.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Countdown timer
            Text(_formatCountdown(_timeUntilStart), style: textTheme.displayMedium, textAlign: TextAlign.center),
            Text('UNTIL YOUR GOAL IS ACTIVE', style: textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}