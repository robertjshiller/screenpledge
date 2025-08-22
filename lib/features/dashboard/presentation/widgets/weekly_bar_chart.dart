// lib/features/dashboard/presentation/widgets/weekly_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';

class WeeklyBarChart extends StatelessWidget {
  /// The historical data for past days from the `daily_results` table.
  final List<DailyResult> dailyData;
  /// The live, real-time screen time usage for the current day.
  final Duration timeSpentToday;
  /// The goal limit for the current day.
  final Duration timeLimitToday;

  const WeeklyBarChart({
    super.key,
    required this.dailyData,
    required this.timeSpentToday,
    required this.timeLimitToday,
  });

  /// ✅ ADDED: A helper function to format Durations for the tooltip message.
  String _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) return "0m";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final weekDays = List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));
    
    final resultsMap = {
      for (var result in dailyData) DateTime(result.date.year, result.date.month, result.date.day): result
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Last 7 Days',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekDays.map((day) {
                final dateOnly = DateTime(day.year, day.month, day.day);
                final isToday = dateOnly == todayDateOnly;
                final historicalResult = resultsMap[dateOnly];

                Color barColor;
                double barHeight;
                String tooltipMessage;

                if (isToday) {
                  // --- LOGIC FOR TODAY'S BAR (LIVE DATA) ---
                  final hasExceeded = timeSpentToday > timeLimitToday;
                  barColor = hasExceeded ? Colors.red.shade400 : AppColors.buttonFill;

                  final progress = (timeLimitToday.inSeconds > 0)
                      ? timeSpentToday.inSeconds / timeLimitToday.inSeconds
                      : 0.0;
                  barHeight = (progress * 100.0).clamp(5.0, 120.0);
                  
                  // Tooltip message for today's live data.
                  tooltipMessage = 'Today\n'
                                   'Used: ${_formatDuration(timeSpentToday)}\n'
                                   'Goal: ${_formatDuration(timeLimitToday)}';

                } else {
                  // --- LOGIC FOR PAST DAYS (HISTORICAL DATA) ---
                  final outcome = historicalResult?.outcome;
                  
                  if (historicalResult != null && historicalResult.timeLimit.inSeconds > 0) {
                    final progress = historicalResult.timeSpent.inSeconds / historicalResult.timeLimit.inSeconds;
                    barHeight = (progress * 100.0).clamp(5.0, 120.0);
                  } else {
                    barHeight = 10.0;
                  }

                  switch (outcome) {
                    case DailyOutcome.success:
                      barColor = AppColors.buttonFill;
                      break;
                    case DailyOutcome.failure:
                      barColor = Colors.red.shade400;
                      if (barHeight < 100) barHeight = 100;
                      break;
                    case DailyOutcome.paused:
                    case DailyOutcome.forgiven:
                      barColor = AppColors.inactive;
                      barHeight = 40.0;
                      break;
                    default:
                      barColor = AppColors.inactive.withAlpha(100);
                      barHeight = 10.0;
                  }

                  // Tooltip message for historical data.
                  if (historicalResult != null) {
                    final dayOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
                    tooltipMessage = '$dayOfWeek\n'
                                     'Used: ${_formatDuration(historicalResult.timeSpent)}\n'
                                     'Goal: ${_formatDuration(historicalResult.timeLimit)}';
                  } else {
                    final dayOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
                    tooltipMessage = '$dayOfWeek\nNo Goal Set';
                  }
                }

                // The bar itself, now wrapped in a Tooltip widget.
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    // ✅ CHANGED: The Column is now wrapped in a Tooltip.
                    // On mobile, this will show on a long-press.
                    // On desktop/web, it will show on hover.
                    child: Tooltip(
                      message: tooltipMessage,
                      // Basic styling for the tooltip to make it readable.
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      preferBelow: false, // Show the tooltip above the bar.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? AppColors.primaryText : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}