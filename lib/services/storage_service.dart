import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_entry.dart';

class StorageService {
  static const String _reflectionKey = 'daily_reflection';

  String _getEntriesKeyForDate(DateTime date) {
    return 'time_entries_${date.year}_${date.month}_${date.day}';
  }

  Future<List<TimeEntry>> loadEntries(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getEntriesKeyForDate(date);
    final String? entriesJson = prefs.getString(key);

    if (entriesJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(entriesJson);
    return decoded.map((json) => TimeEntry.fromJson(json)).toList();
  }

  Future<void> saveEntries(DateTime date, List<TimeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getEntriesKeyForDate(date);
    final List<Map<String, dynamic>> jsonList =
        entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  Future<void> addEntry(DateTime date, TimeEntry entry) async {
    final entries = await loadEntries(date);
    entries.add(entry);
    await saveEntries(date, entries);
  }

  Future<void> deleteEntry(DateTime date, String id) async {
    final entries = await loadEntries(date);
    entries.removeWhere((entry) => entry.id == id);
    await saveEntries(date, entries);
  }

  Future<void> updateEntry(DateTime date, TimeEntry updatedEntry) async {
    final entries = await loadEntries(date);
    final index = entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      entries[index] = updatedEntry;
      await saveEntries(date, entries);
    }
  }

  Future<String?> loadReflection(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_reflectionKey}_${date.year}_${date.month}_${date.day}';
    return prefs.getString(key);
  }

  Future<void> saveReflection(DateTime date, String reflection) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_reflectionKey}_${date.year}_${date.month}_${date.day}';
    await prefs.setString(key, reflection);
  }

  /// Export all stored entries and reflections as a JSON string.
  /// Returns a JSON string containing all stored time entries and reflections.
  ///
  /// The format is a simple map keyed by the internal SharedPreferences key so
  /// the export is straightforward to parse for re-import or analysis outside
  /// the app. Keys are left intact (e.g. `time_entries_2026_1_7`) to preserve
  /// the date context.
  Future<String> exportAllAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final Map<String, dynamic> out = {};

    // Gather entries
    for (final key in keys) {
      if (key.startsWith('time_entries_')) {
        final entriesJson = prefs.getString(key);
        if (entriesJson != null) {
          out[key] = jsonDecode(entriesJson);
        }
      }
    }

    // Gather reflections
    for (final key in keys) {
      if (key.startsWith('${_reflectionKey}_')) {
        final reflection = prefs.getString(key);
        if (reflection != null) {
          out[key] = reflection;
        }
      }
    }

    return jsonEncode(out);
  }

  /// Export all stored entries as CSV. Each row: date,id,startTime,endTime,activityName,category,durationMinutes
  Future<String> exportAllAsCsv() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final buffer = StringBuffer();
    buffer.writeln('date,id,startTime,endTime,activityName,category,durationMinutes');

    for (final key in keys) {
      if (key.startsWith('time_entries_')) {
        final entriesJson = prefs.getString(key);
        if (entriesJson == null) continue;
        final List<dynamic> decoded = jsonDecode(entriesJson);
        for (final e in decoded) {
          final entry = TimeEntry.fromJson(e);
          final dateKey = key.replaceFirst('time_entries_', '');
          buffer.writeln(
              '$dateKey,${entry.id},${entry.startTime.toIso8601String()},${entry.endTime.toIso8601String()},"${_escapeCsv(entry.activityName)}",${entry.category.name},${entry.durationMinutes}');
        }
      }
    }

    return buffer.toString();
  }

  String _escapeCsv(String input) {
    // basic CSV escaping: double quotes -> double them, wrap in quotes if needed
    final escaped = input.replaceAll('"', '""');
    if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  /// Clears all stored data (entries + reflections)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();

    for (final key in keys) {
      if (key.startsWith('time_entries_') || key.startsWith('${_reflectionKey}_')) {
        await prefs.remove(key);
      }
    }
  }
}
