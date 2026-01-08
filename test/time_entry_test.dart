import 'package:flutter_test/flutter_test.dart';
import 'package:focuslog/models/time_entry.dart';

void main() {
  test('fromJson treats endTime before startTime as crossing midnight', () {
    final json = {
      'id': 't1',
      'startTime': '2026-01-08T23:30:00Z',
      'endTime': '2026-01-08T01:15:00Z', // earlier than start -> next day
      'activityName': 'Late study',
      'category': 'study',
      'energy': null,
      'intent': null,
    };

    final entry = TimeEntry.fromJson(json);

    expect(entry.endTime.isAfter(entry.startTime), isTrue);
    // Duration should be 105 minutes (23:30 -> 01:15 = 1h45m)
    expect(entry.durationMinutes, equals(105));
  });

  test('fromJson treats invalid optional fields as null', () {
    final json = {
      'id': 't2',
      'startTime': '2026-01-08T10:00:00Z',
      'endTime': '2026-01-08T11:00:00Z',
      'activityName': 'Meeting',
      'category': 'work',
      'energy': 'not-a-value',
      'intent': 'unknown',
    };

    final entry = TimeEntry.fromJson(json);
    expect(entry.energyLevel, isNull);
    expect(entry.intent, isNull);
  });
}
