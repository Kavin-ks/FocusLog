import 'package:flutter/material.dart';
import '../models/time_entry.dart';

class CategorySummary extends StatelessWidget {
  final List<TimeEntry> entries;

  const CategorySummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final Map<ActivityCategory, int> totals = {};
    for (final e in entries) {
      totals[e.category] = (totals[e.category] ?? 0) + e.durationMinutes;
    }

    final list = ActivityCategory.values.map((cat) {
      final minutes = totals[cat] ?? 0;
      return MapEntry(cat, minutes);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By category', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...list.map((entry) {
              final minutes = entry.value;
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: _categoryColor(entry.key)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.key.displayName, style: Theme.of(context).textTheme.bodyLarge)),
                    Text(hours > 0 ? '$hours h $mins min' : '$mins min', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.study:
        return const Color(0xFF4CAF50);
      case ActivityCategory.work:
        return const Color(0xFF2196F3);
      case ActivityCategory.rest:
        return const Color(0xFFFF9800);
      case ActivityCategory.scroll:
        return const Color(0xFF9C27B0);
      case ActivityCategory.other:
        return const Color(0xFF757575);
    }
  }
}
