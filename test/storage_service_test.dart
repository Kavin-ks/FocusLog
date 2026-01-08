import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslog/services/storage_service.dart';
import 'package:focuslog/models/time_entry.dart';

void main() {
  test('loadEntries normalizes cross-midnight endTimes and persists normalized JSON', () async {
    final key = 'time_entries_2026_1_8';

    // Create an entry JSON where endTime is earlier than startTime (cross-midnight)
    final rawList = [
      {
        'id': 'x1',
        'startTime': '2026-01-08T22:45:00Z',
        'endTime': '2026-01-08T01:30:00Z', // earlier -> should be interpreted as next day
        'activityName': 'Overnight work',
        'category': 'work',
        'energy': null,
        'intent': null,
      }
    ];

    // Set mock prefs with the raw (unnormalized) JSON string
    SharedPreferences.setMockInitialValues({key: jsonEncode(rawList)});

    final storage = StorageService();
    final date = DateTime(2026, 1, 8);

    final entries = await storage.loadEntries(date, []);
    expect(entries.length, equals(1));

    final e = entries.first;
    // endTime should now be after startTime once normalized
    expect(e.endTime.isAfter(e.startTime), isTrue);
    expect(e.durationMinutes, greaterThan(0));

    // Verify the normalized JSON was persisted back to prefs
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getString(key)!;
    final decoded = jsonDecode(persisted) as List<dynamic>;
    final persistedEnd = decoded.first['endTime'] as String;

    // Persisted endTime should reflect the corrected (next-day) time.
    final parsedPersistedEnd = DateTime.parse(persistedEnd);
    expect(parsedPersistedEnd.isAfter(DateTime.parse(rawList.first['startTime'] as String)), isTrue);
  });

  test('saveEntries persists normalized entries (normalized endTime/nullable optional fields)', () async {
    final key = 'time_entries_2026_1_9';
    SharedPreferences.setMockInitialValues({});

    final storage = StorageService();
    final date = DateTime(2026, 1, 9);

    final entry = TimeEntry(
      id: 's1',
      startTime: DateTime.parse('2026-01-09T23:50:00Z'),
      endTime: DateTime.parse('2026-01-09T00:10:00Z'), // earlier -> next day
      activityName: 'Late session',
      category: ActivityCategory.study,
      energyLevel: null,
      intent: null,
    );

    await storage.saveEntries(date, [entry]);

    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getString(key)!;
    final decoded = jsonDecode(persisted) as List<dynamic>;
    final persistedEnd = decoded.first['endTime'] as String;
    final parsedPersistedEnd = DateTime.parse(persistedEnd);

    // Persisted end should be after the start
    expect(parsedPersistedEnd.isAfter(entry.startTime), isTrue);
  });
}
