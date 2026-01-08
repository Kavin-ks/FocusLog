import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_entry.dart';

class TimelineView extends StatelessWidget {
  final List<TimeEntry> entries;
  final int? maxEntries; // optional limit for pagination / page size

  const TimelineView({super.key, required this.entries, this.maxEntries});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(entries)..sort((a, b) => a.startTime.compareTo(b.startTime));
    final display = (maxEntries != null) ? sorted.take(maxEntries!).toList() : sorted;

    return Column(
      children: display.map((entry) {
        // top/bottom radius variables removed (unused)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time column
            Container(
              width: 80,
              padding: const EdgeInsets.only(top: 12, right: 8),
              child: Text(
                DateFormat('h:mm a').format(entry.startTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            
            // Timeline bar + block
            Expanded(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // vertical line
                        Container(
                          width: 4,
                          height: 12,
                          color: Theme.of(context).dividerColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.activityName, style: Theme.of(context).textTheme.bodyLarge),
                                  const SizedBox(height: 6),
                                  Text('${DateFormat('h:mm a').format(entry.startTime)} - ${DateFormat('h:mm a').format(entry.endTime)}',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  Text(entry.category.displayName, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
