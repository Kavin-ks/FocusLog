import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_entry.dart';

class DaySummary extends StatelessWidget {
  final List<TimeEntry> entries;
  final DateTime date;

  const DaySummary({
    super.key,
    required this.entries,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    // Group by activity name
    final Map<String, int> activityTotals = {};
    for (final entry in entries) {
      // `TimeEntry` stores the activity name in `activityName`.
      activityTotals[entry.activityName] = 
          (activityTotals[entry.activityName] ?? 0) + entry.durationMinutes;
    }
    
    final sortedActivities = activityTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            // Total time
            Row(
              children: [
                Text(
                  'Total logged: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  hours > 0 
                      ? '$hours h $minutes min' 
                      : '$minutes min',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            if (sortedActivities.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              // Activity breakdown
              ...sortedActivities.map((entry) {
                final activityMinutes = entry.value;
                final activityHours = activityMinutes ~/ 60;
                final activityMins = activityMinutes % 60;
                final percentage = totalMinutes > 0 
                    ? (activityMinutes / totalMinutes * 100).round() 
                    : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        activityHours > 0
                            ? '$activityHours h $activityMins min'
                            : '$activityMins min',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
