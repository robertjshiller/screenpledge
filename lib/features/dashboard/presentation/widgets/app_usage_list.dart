// lib/features/dashboard/presentation/widgets/app_usage_list.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screen_time_channel/app_usage_stat.dart';

class AppUsageList extends StatelessWidget {
  final List<AppUsageStat> usageStats;

  const AppUsageList({super.key, required this.usageStats});

  @override
  Widget build(BuildContext context) {
    // If there is no usage data, show a placeholder message.
    if (usageStats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No app usage data available for today.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Today\'s App Usage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the list
          itemCount: usageStats.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final stat = usageStats[index];
            final hours = stat.usage.inHours;
            final minutes = stat.usage.inMinutes.remainder(60);

            return ListTile(
              leading: Image.memory(stat.app.icon, width: 40, height: 40),
              title: Text(stat.app.name),
              trailing: Text('${hours}h ${minutes}m'),
            );
          },
        ),
      ],
    );
  }
}