import 'package:flutter_test/flutter_test.dart';
import 'package:focuslog/widgets/baseline_comparison.dart';
import 'package:focuslog/models/time_entry.dart';

void main() {
  final category = ActivityCategory.study;

  test('High-energy appears earlier when today starts earlier than baseline', () {
    // Baseline: 7 days of high-energy at noon
    final baseline = List<TimeEntry>.generate(7, (i) {
      final start = DateTime(2026, 1, i + 1, 12, 0);
      return TimeEntry(
        id: 'b$i',
        startTime: start,
        endTime: start.add(const Duration(minutes: 60)),
        activityName: 'Work',
        category: category,
        energyLevel: EnergyLevel.high,
      );
    });

    // Today: high-energy at 9am
    final todayStart = DateTime(2026, 1, 8, 9, 0);
    final today = [
      TimeEntry(
        id: 't1',
        startTime: todayStart,
        endTime: todayStart.add(const Duration(minutes: 60)),
        activityName: 'Work',
        category: category,
        energyLevel: EnergyLevel.high,
      ),
    ];

    final items = BaselineComparison.generateEnergyIntentItems(today, baseline);
    // items is a List<String> of neutral sentences
    final texts = items;

    expect(texts.any((t) => t.contains('High-energy') && t.contains('earlier')), isTrue);
  });

  test('Unintentional time similar to recent days when ratios close to 1', () {
    // Baseline: 7 days with 60 minutes unintentional each
    final baseline = List<TimeEntry>.generate(7, (i) {
      final start = DateTime(2026, 1, i + 1, 10, 0);
      return TimeEntry(
        id: 'b$i',
        startTime: start,
        endTime: start.add(const Duration(minutes: 60)),
        activityName: 'Scroll',
        category: category,
        intent: IntentTag.unintentional,
      );
    });

    // Today: 60 minutes unintentional
    final todayStart = DateTime(2026, 1, 8, 11, 0);
    final today = [
      TimeEntry(
        id: 't1',
        startTime: todayStart,
        endTime: todayStart.add(const Duration(minutes: 60)),
        activityName: 'Scroll',
        category: category,
        intent: IntentTag.unintentional,
      ),
    ];

    final items = BaselineComparison.generateEnergyIntentItems(today, baseline);
    final texts = items;

    expect(texts.any((t) => t.contains('Unintentional time') && t.contains('similar')), isTrue);
  });

  test('Fallback when no data', () {
    final items = BaselineComparison.generateEnergyIntentItems([], []);
    final texts = items;

    expect(texts, contains('Energy and intent patterns were similar to recent days.'));
  });
}
