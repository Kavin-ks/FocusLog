import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/time_entry.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class BaselineComparison extends StatelessWidget {
  final List<TimeEntry> todayEntries;
  final DateTime date;
  final List<ActivityCategory> allCategories;

  const BaselineComparison({
    super.key,
    required this.todayEntries,
    required this.date,
    required this.allCategories,
  });

  /// Generate neutral comparison language based on difference ratio
  /// Returns text like "slightly higher", "about the same", "notably lower", etc.
  String _getComparisonText(int today, int baseline) {
    // If baseline is zero we avoid making comparative claims that imply a
    // trend; instead state presence/absence plainly.
    if (baseline == 0) {
      return today > 0 ? 'first time logged' : 'not logged';
    }

    final ratio = today / baseline;

    // Use neutral phrasing focused on time: "more time" / "less time".
    if (ratio > 1.3) {
      return 'notably more time';
    } else if (ratio > 1.1) {
      return 'slightly more time';
    } else if (ratio > 0.9 && ratio < 1.1) {
      return 'about the same';
    } else if (ratio > 0.7) {
      return 'slightly less time';
    } else {
      return 'notably less time';
    }
  }

  /// Format duration as "1h 30m" or "45m"
  String _formatDuration(int minutes) {
    if (minutes < 0) minutes = 0;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '$hours h ${mins > 0 ? "$mins m" : ""}'.trim();
    }
    return '$mins m';
  }

  /// Group entries by category and sum duration
  Map<ActivityCategory, int> _getCategoryTotals(List<TimeEntry> entries) {
    final categoryTotals = <ActivityCategory, int>{};
    for (final entry in entries) {
      categoryTotals[entry.category] =
          (categoryTotals[entry.category] ?? 0) + entry.durationMinutes;
    }
    return categoryTotals;
  }


  static double? _weightedAverageStartHour(List<TimeEntry> entries, EnergyLevel level) {
    double weightedSum = 0.0;
    int totalMinutes = 0;
    for (final e in entries) {
      if (e.energyLevel == level) {
        final startHour = e.startTime.hour + e.startTime.minute / 60.0;
        weightedSum += startHour * e.durationMinutes;
        totalMinutes += e.durationMinutes;
      }
    }
    if (totalMinutes == 0) return null;
    return weightedSum / totalMinutes;
  }


  static List<String> generateEnergyIntentItems(List<TimeEntry> todayEntries, List<TimeEntry> baselineEntries) {
    final List<String> items = [];

    // Energy timing comparisons (High, Neutral, Low)
    for (final level in [EnergyLevel.high, EnergyLevel.neutral, EnergyLevel.low]) {
      final todayAvg = _weightedAverageStartHour(todayEntries, level);
      final baseAvg = _weightedAverageStartHour(baselineEntries, level);
      if (todayAvg != null && baseAvg != null) {
        final diff = todayAvg - baseAvg; // positive => later today
        final absDiff = diff.abs();
        final levelLabel = level == EnergyLevel.high ? 'High-energy' : level == EnergyLevel.low ? 'Low-energy' : 'Neutral-energy';

        if (absDiff >= 1.0) {
          final when = diff < 0 ? 'earlier' : 'later';
          items.add('$levelLabel was $when than usual.');
        } else if (absDiff >= 0.4) {
          final when = diff < 0 ? 'slightly earlier' : 'slightly later';
          items.add('$levelLabel was $when today.');
        }
      }
    }

    // Intent: Unintentional time comparison
    final todayUnintent = todayEntries.where((e) => e.intent == IntentTag.unintentional).fold<int>(0, (s, e) => s + e.durationMinutes);
    final baseUnintentTotal = baselineEntries.where((e) => e.intent == IntentTag.unintentional).fold<int>(0, (s, e) => s + e.durationMinutes);
    final baseUnintentAvg = (baseUnintentTotal / 7.0);

    if (baseUnintentAvg < 0.5) {
      if (todayUnintent == 0) {
        // nothing notable
      } else {
        items.add('Unintentional time was recorded today; it was uncommon last week.');
      }
    } else {
      final ratio = todayUnintent / baseUnintentAvg;
      if (ratio >= 1.3) {
        items.add('Unintentional time was more than recent days.');
      } else if (ratio >= 1.1) {
        items.add('Unintentional time was slightly more than recent days.');
      } else if (ratio >= 0.9 && ratio <= 1.1) {
        items.add('Unintentional time was similar to recent days.');
      } else if (ratio >= 0.7) {
        items.add('Unintentional time was slightly less than recent days.');
      } else {
        items.add('Unintentional time was less than recent days.');
      }
    }

    if (items.isEmpty) {
      items.add('Energy and intent patterns were similar to recent days.');
    }

    return items;
  }

  Future<List<TimeEntry>> _loadLastWeekEntries(BuildContext context) async {
    StorageService storage;
    try {
      storage = Provider.of<StorageService>(context, listen: false);
    } catch (_) {
      // No provider in tests or simple use-cases: fall back to a plain StorageService
      storage = StorageService(AuthService());
    }

    final endDate = DateTime(date.year, date.month, date.day);
    final startDate = endDate.subtract(const Duration(days: 7));

    final entries = await (storage as dynamic).loadEntriesForDateRange(startDate, endDate);

    // Exclude today from the baseline calculation
    return entries
        .where((e) {
          final eDate = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
          final today = DateTime(date.year, date.month, date.day);
          return !eDate.isAtSameMomentAs(today);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TimeEntry>>(
      future: _loadLastWeekEntries(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load baseline data',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          );
        }

        final lastWeekEntries = snapshot.data ?? [];

        bool hasSufficientBaseline(List<TimeEntry> entries) {
          final dates = <String>{};
          for (final e in entries) {
            final d = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
            dates.add('${d.year}-${d.month}-${d.day}');
          }
          return dates.length >= 4; // threshold: data on >= 4 distinct days
        }

        final sufficientBaseline = hasSufficientBaseline(lastWeekEntries);

      
        if (!sufficientBaseline) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Compared to last week — not enough recent data to compare',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(160),
                    ),
              ),
            ),
          );
        }

        // Calculate category totals for today and baseline average
        final todayTotals = _getCategoryTotals(todayEntries);
        final lastWeekTotals = _getCategoryTotals(lastWeekEntries);

        // Calculate baseline average (7-day average)
        final baselineAverages = <ActivityCategory, double>{};
        for (final category in lastWeekTotals.keys) {
          baselineAverages[category] = lastWeekTotals[category]! / 7.0;
        }

        // Get all categories that appear in today's entries
        final categoriesToShow = todayTotals.keys.toList()
          ..sort((a, b) => (todayTotals[b] ?? 0).compareTo(todayTotals[a] ?? 0));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compared to last week',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600
                      ),
                ),
                const SizedBox(height: 12),
                ...categoriesToShow.map((category) {
                  final todayMinutes = todayTotals[category] ?? 0;
                  final baselineMinutes = (baselineAverages[category] ?? 0).round();
                  final comparison = _getComparisonText(todayMinutes, baselineMinutes);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today: ${_formatDuration(todayMinutes)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last week avg: ${_formatDuration(baselineMinutes)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withAlpha(25) ??
                                    Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                comparison,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                Builder(builder: (context) {
                  final sentences = BaselineComparison.generateEnergyIntentItems(todayEntries, lastWeekEntries);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy & intent',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...sentences.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $s', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(200))),
                      )),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

}
