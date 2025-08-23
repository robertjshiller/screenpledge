// lib/features/dashboard/presentation/widgets/weekly_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';

class WeeklyBarChart extends StatelessWidget {
  /// The historical data for past days from the `daily_results` table.
  final List<DailyResult> dailyData;
  /// The raw historical usage data from the device itself.
  final Map<DateTime, Duration> historicalUsage;
  /// The live, real-time screen time usage for the current day.
  final Duration timeSpentToday;
  /// The goal limit for the current day.
  final Duration timeLimitToday;

  const WeeklyBarChart({
    super.key,
    required this.dailyData,
    required this.historicalUsage,
    required this.timeSpentToday,
    required this.timeLimitToday,
  });

  String _formatDuration(Duration duration) {
    if (duration.inMinutes == 0) return "0m";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
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

    // Find the maximum usage in the last 7 days to normalize bar heights.
    // This ensures the chart is always scaled appropriately.
    final maxUsage = historicalUsage.values.fold(
      timeSpentToday,
      (max, current) => current > max ? current : max,
    );
    final maxUsageMinutes = maxUsage.inMinutes > 0 ? maxUsage.inMinutes : 60.0; // Avoid division by zero

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
                
                // ✅ CHANGED: The source of truth for time is now the device data.
                final timeUsed = isToday ? timeSpentToday : historicalUsage[dateOnly] ?? Duration.zero;
                final timeLimit = isToday ? timeLimitToday : historicalResult?.timeLimit ?? Duration.zero;

                Color barColor;
                String tooltipMessage;

                // --- Determine Bar Color ---
                if (historicalResult != null) {
                  // If we have a recorded outcome, it's the source of truth for color.
                  switch (historicalResult.outcome) {
                    case DailyOutcome.success:
                      barColor = AppColors.buttonFill;
                      break;
                    case DailyOutcome.failure:
                      barColor = Colors.red.shade400;
                      break;
                    default:
                      barColor = AppColors.inactive;
                  }
                } else {
                  // For days with no recorded outcome (e.g., a new user's past),
                  // the color is neutral/informational.
                  barColor = AppColors.inactive.withAlpha(100);
                }
                
                // The "Today" bar's color is always live.
                if (isToday) {
                  barColor = timeUsed > timeLimit ? Colors.red.shade400 : AppColors.buttonFill;
                }

                // --- Determine Bar Height ---
                // The height is always relative to the max usage in the last 7 days.
                final barHeight = (timeUsed.inMinutes / maxUsageMinutes * 120.0).clamp(5.0, 150.0);

                // --- Determine Tooltip Message ---
                final dayOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
                if (timeLimit.inSeconds > 0) {
                  tooltipMessage = '${isToday ? 'Today' : dayOfWeek}\n'
                                   'Used: ${_formatDuration(timeUsed)}\n'
                                   'Goal: ${_formatDuration(timeLimit)}';
                } else {
                  tooltipMessage = '${isToday ? 'Today' : dayOfWeek}\n'
                                   'Used: ${_formatDuration(timeUsed)}\n'
                                   'No Goal Set';
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Tooltip(
                      message: tooltipMessage,
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      preferBelow: false,
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