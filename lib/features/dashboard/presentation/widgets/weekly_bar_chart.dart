
import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for 7 days.
    // For now, we are simplifying the logic for determining success/failure/no limit.
    // In the future, this will be based on actual screen time data and goal limits.
    final List<Map<String, dynamic>> dailyData = [
      {'day': 'Day 1', 'status': 'success', 'value': 0.8}, // Green
      {'day': 'Day 2', 'status': 'failure', 'value': 1.2}, // Red
      {'day': 'Day 3', 'status': 'no_limit', 'value': 0.5}, // Grey
      {'day': 'Day 4', 'status': 'success', 'value': 0.7}, // Green
      {'day': 'Day 5', 'status': 'failure', 'value': 1.5}, // Red
      {'day': 'Day 6', 'status': 'no_limit', 'value': 0.3}, // Grey
      {'day': 'Day 7', 'status': 'success', 'value': 0.9}, // Green
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Weekly Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 150, // Fixed height for the chart
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyData.map((data) {
                Color barColor;
                // We are simplifying the color logic for now.
                // Future logic will determine success/failure/no_limit based on actual data.
                switch (data['status']) {
                  case 'success':
                    barColor = AppColors.primaryAccent;
                    break;
                  case 'failure':
                    barColor = Colors.red.shade400;
                    break;
                  case 'no_limit':
                    barColor = AppColors.inactive;
                    break;
                  default:
                    barColor = Colors.blueGrey; // Fallback
                }

                // Using a simplified value for bar height for now.
                // In the future, this will represent actual time or progress.
                final double barHeight = (data['value'] as double) * 100; 

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight,
                          width: double.infinity,
                          color: barColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['day'].toString().replaceAll('Day ', ''), // Just show day number
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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
