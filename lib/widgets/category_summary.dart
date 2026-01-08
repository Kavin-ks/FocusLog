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

    final list = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      // Card provides visual separation and elevation for the summary section
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // CrossAxisAlignment.start left-aligns content for consistent, scannable layout
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By category', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...list.map((entry) {
              final minutes = entry.value;
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: _categoryColor(entry.key)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.key.displayName, style: Theme.of(context).textTheme.bodyLarge)),
                    Text(hours > 0 ? '$hours h $mins min' : '$mins min', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
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
    return category.color ?? const Color(0xFF607D8B);
  }
}
