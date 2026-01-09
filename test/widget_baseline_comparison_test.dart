import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslog/widgets/baseline_comparison.dart';
import 'package:focuslog/models/time_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaselineComparison widget', () {
    testWidgets('renders category comparison and high-energy shift with arrow icon', (tester) async {
      // Prepare mock SharedPreferences with 7 days of baseline entries (high-energy at noon)
      final Map<String, Object> values = {};
      final baselineDates = List.generate(7, (i) => DateTime(2026, 1, i + 1));
      for (final d in baselineDates) {
        final key = 'time_entries_${d.year}_${d.month}_${d.day}';
        final entryStart = DateTime(d.year, d.month, d.day, 12, 0);
        final entry = TimeEntry(
          id: 'b_${d.day}',
          startTime: entryStart,
          endTime: entryStart.add(const Duration(minutes: 60)),
          activityName: 'Work',
          category: ActivityCategory.study,
          energyLevel: EnergyLevel.high,
        );
        values[key] = jsonEncode([entry.toJson()]);
      }

      SharedPreferences.setMockInitialValues(values);

      // Today entries: high-energy at 9am
      final todayStart = DateTime(2026, 1, 8, 9, 0);
      final todayEntries = [
        TimeEntry(
          id: 't1',
          startTime: todayStart,
          endTime: todayStart.add(const Duration(minutes: 60)),
          activityName: 'Work',
          category: ActivityCategory.study,
          energyLevel: EnergyLevel.high,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BaselineComparison(todayEntries: todayEntries, date: DateTime(2026, 1, 8), allCategories: [ActivityCategory.study])),
      ));

      // Wait for FutureBuilder to complete
      await tester.pumpAndSettle();

      expect(find.text('Compared to last week'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.textContaining('Today:'), findsOneWidget);
      expect(find.textContaining('Last week avg:'), findsOneWidget);

      // Energy intent item should include High-energy (no icons; neutral phrasing)
      expect(find.textContaining('High-energy'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('renders unintentional similarity message', (tester) async {
      // Baseline: 7 days of unintentional 60min entries
      final Map<String, Object> values = {};
      final baselineDates = List.generate(7, (i) => DateTime(2026, 1, i + 1));
      for (final d in baselineDates) {
        final key = 'time_entries_${d.year}_${d.month}_${d.day}';
        final entryStart = DateTime(d.year, d.month, d.day, 10, 0);
        final entry = TimeEntry(
          id: 'b_${d.day}',
          startTime: entryStart,
          endTime: entryStart.add(const Duration(minutes: 60)),
          activityName: 'Scroll',
          category: ActivityCategory.scroll,
          intent: IntentTag.unintentional,
        );
        values[key] = jsonEncode([entry.toJson()]);
      }

      SharedPreferences.setMockInitialValues(values);

      // Today: 60 minutes unintentional
      final todayStart = DateTime(2026, 1, 8, 11, 0);
      final todayEntries = [
        TimeEntry(
          id: 't1',
          startTime: todayStart,
          endTime: todayStart.add(const Duration(minutes: 60)),
          activityName: 'Scroll',
          category: ActivityCategory.scroll,
          intent: IntentTag.unintentional,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BaselineComparison(todayEntries: todayEntries, date: DateTime(2026, 1, 8), allCategories: ActivityCategory.builtInCategories)),
      ));

      await tester.pumpAndSettle();

      expect(find.textContaining('Unintentional time'), findsWidgets);
      expect(find.textContaining('similar'), findsWidgets);
    });

    testWidgets('hides comparisons when baseline is insufficient', (tester) async {
      // Baseline: only 1 day of historical data -> insufficient
      final Map<String, Object> values = {};
      final d = DateTime(2026, 1, 1);
      final key = 'time_entries_${d.year}_${d.month}_${d.day}';
      final entryStart = DateTime(d.year, d.month, d.day, 12, 0);
      final entry = TimeEntry(
        id: 'b_1',
        startTime: entryStart,
        endTime: entryStart.add(const Duration(minutes: 60)),
        activityName: 'Work',
        category: ActivityCategory.study,
        energyLevel: EnergyLevel.high,
      );
      values[key] = jsonEncode([entry.toJson()]);

      SharedPreferences.setMockInitialValues(values);

      // Today entries: any entries
      final todayStart = DateTime(2026, 1, 8, 9, 0);
      final todayEntries = [
        TimeEntry(
          id: 't1',
          startTime: todayStart,
          endTime: todayStart.add(const Duration(minutes: 60)),
          activityName: 'Work',
          category: ActivityCategory.study,
          energyLevel: EnergyLevel.high,
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BaselineComparison(todayEntries: todayEntries, date: DateTime(2026, 1, 8), allCategories: [ActivityCategory.study])),
      ));

      await tester.pumpAndSettle();

      // Should show a quiet note and not show category or energy comparisons
      expect(find.textContaining('not enough recent data'), findsOneWidget);
      expect(find.text('Study'), findsNothing);
      expect(find.textContaining('Energy & intent'), findsNothing);
    });
  });
}
