import 'package:flutter/material.dart';
import '../models/time_entry.dart';
import 'package:intl/intl.dart';

class TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TimeEntryCard({
    super.key,
    required this.entry,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.category),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Entry details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.activityName,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(entry.startTime)} - ${timeFormat.format(entry.endTime)} · ${entry.category.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Delete button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDelete,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                  padding: const EdgeInsets.all(8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.study:
        return const Color(0xFF4CAF50); // Green
      case ActivityCategory.work:
        return const Color(0xFF2196F3); // Blue
      case ActivityCategory.rest:
        return const Color(0xFFFF9800); // Orange
      case ActivityCategory.scroll:
        return const Color(0xFF9C27B0); // Purple
      case ActivityCategory.other:
        return const Color(0xFF757575); // Grey
    }
  }
}
