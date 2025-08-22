// lib/features/dashboard/presentation/widgets/progress_ring.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// A widget that displays a circular progress ring, typically used to show
/// goal progress or statistics.
class ProgressRing extends StatelessWidget {
  /// The progress value to display, from 0.0 to 1.0.
  final double progress;

  /// The color of the progress indicator arc.
  final Color progressColor;

  /// The color of the background arc.
  final Color backgroundColor;

  /// The width of the ring.
  final double strokeWidth;

  /// An optional widget to display in the center of the ring.
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.progressColor,
    this.backgroundColor = AppColors.inactive,
    this.strokeWidth = 12.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressRingPainter(
        progress: progress,
        progressColor: progressColor,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      ),
      child: Center(child: child),
    );
  }
}

/// The custom painter that draws the actual progress ring.
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - (strokeWidth / 2);
    const startAngle = -pi / 2; // Start from the top

    // Paint for the background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Paint for the progress ring
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round // Rounded ends for the progress arc
      ..style = PaintingStyle.stroke;

    // Draw the background ring
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the progress arc
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        progressColor != oldDelegate.progressColor ||
        backgroundColor != oldDelegate.backgroundColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
