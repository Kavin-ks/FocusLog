import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_entry.dart';

/// Simple key-value-backed storage for time entries and reflections.
///
/// Normalization guarantees:
/// - When entries are loaded they are normalized (cross-midnight `endTime`
///   corrections are applied and invalid/missing optional fields are treated as
///   `null`). If normalization changes the stored representation, the
///   normalized JSON is persisted back to preferences so on-disk data follows
///   a consistent structure.
/// - When entries are saved they are normalized before being written.
/// Storage service responsibilities and migration-safety notes:
///
/// - This service stores per-day `TimeEntry` lists in SharedPreferences
///   using a date-based key. Historically entries could be written with
///   slightly different shapes or with `endTime` earlier than `startTime`.
/// - `loadEntries` performs defensive parsing: it attempts to parse each
///   stored item individually, skips unrecoverable/malformed items, and
///   writes back a normalized list. This ensures older app versions or
///   corrupted data don't crash the UI and that storage is migrated to a
///   consistent format on read.
/// - `saveEntries` normalizes entries before writing so on-disk JSON is
///   consistent (normalized times, explicit keys for optional fields).
/// - Optional fields (`energy`, `intent`) are treated as nullable; missing
///   or invalid values are stored/read as `null` to preserve intent and
///   avoid misleading defaults.
class StorageService {
  static const String _reflectionKey = 'daily_reflection';

  String _getEntriesKeyForDate(DateTime date) {
    return 'time_entries_${date.year}_${date.month}_${date.day}';
  }

  Future<List<TimeEntry>> loadEntries(DateTime date, [List<ActivityCategory>? customCategories]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getEntriesKeyForDate(date);
    final String? entriesJson = prefs.getString(key);

    if (entriesJson == null) {
      return [];
    }
    // Defensive parsing for migration safety.
    // Older or corrupted data may contain malformed items; we attempt to
    // parse each entry individually, skip entries we can't reasonably
    // recover, and persist a cleaned/normalized representation back to
    // storage so future loads are stable.
    List<dynamic> decoded;
    try {
      final raw = jsonDecode(entriesJson);
      if (raw is List<dynamic>) {
        decoded = raw;
      } else {
        // Unexpected top-level shape: replace with empty list.
        await prefs.setString(key, jsonEncode([]));
        return [];
      }
    } catch (_) {
      // If stored string isn't valid JSON, clear the entry list for safety.
      await prefs.setString(key, jsonEncode([]));
      return [];
    }

    final List<TimeEntry> entries = [];
    var changed = false; // whether we need to overwrite stored JSON

    for (final item in decoded) {
      try {
        Map<String, dynamic> map;
        if (item is Map<String, dynamic>) {
          map = item;
        } else if (item is Map) {
          // convert dynamic-keyed map into Map<String,dynamic>
          map = item.map((k, v) => MapEntry(k.toString(), v));
          changed = true;
        } else {
          // Unrecoverable type for this item; skip it.
          changed = true;
          continue;
        }

        // Basic required fields check
        if (!(map.containsKey('startTime') && map.containsKey('endTime') && map.containsKey('activityName'))) {
          // Skip entries missing required fields; mark changed so we persist a cleaned list.
          changed = true;
          continue;
        }

        // Parse into TimeEntry using existing normalization logic. If parsing
        // fails (bad dates, etc.) we'll skip the entry rather than crash.
        final entry = TimeEntry.fromJson(map, customCategories);
        entries.add(entry);
      } catch (_) {
        // Parsing failed for this entry: skip and continue
        changed = true;
        continue;
      }
    }

    // Persist a normalized representation back to storage if necessary.
    final normalizedJsonList = entries.map((e) => e.toJson()).toList();
    final normalizedString = jsonEncode(normalizedJsonList);
    if (changed || normalizedString != entriesJson) {
      try {
        await prefs.setString(key, normalizedString);
      } catch (_) {
        // ignore write failures; we still return the parsed entries
      }
    }

    return entries;
  }

  Future<void> saveEntries(DateTime date, List<TimeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getEntriesKeyForDate(date);
    // Normalize entries before persisting to ensure consistent stored structure
    final List<Map<String, dynamic>> jsonList =
        entries.map((entry) => entry.normalized().toJson()).toList();
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

  Future<List<TimeEntry>> loadEntriesForDateRange(
    DateTime startDate,
    DateTime endDate, [
    List<ActivityCategory>? customCategories,
  ]) async {
    final List<TimeEntry> allEntries = [];
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final entries = await loadEntries(current, customCategories);
      allEntries.addAll(entries);
      current = current.add(const Duration(days: 1));
    }
    
    return allEntries;
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

  Future<String> exportAllAsCsv() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final buffer = StringBuffer();
    buffer.writeln('date,id,startTime,endTime,activityName,category,durationMinutes,energy,intent');

    for (final key in keys) {
      if (key.startsWith('time_entries_')) {
        final entriesJson = prefs.getString(key);
        if (entriesJson == null) continue;
        final List<dynamic> decoded = jsonDecode(entriesJson);
        for (final e in decoded) {
          final entry = TimeEntry.fromJson(e);
          final dateKey = key.replaceFirst('time_entries_', '');
          final energyName = entry.energyLevel?.name ?? '';
          final intentName = entry.intent?.name ?? '';
          buffer.writeln(
              '$dateKey,${entry.id},${entry.startTime.toIso8601String()},${entry.endTime.toIso8601String()},"${_escapeCsv(entry.activityName)}",${entry.category.id},${entry.durationMinutes},$energyName,$intentName');
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

  Future<bool> isCategoryUsed(String categoryId) async {
    // Check if a category ID is referenced by any stored time entries
    // Used before deleting custom categories to prevent accidental data loss
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('time_entries_')).toList();
    for (final key in keys) {
      final entriesJson = prefs.getString(key);
      if (entriesJson == null) continue;
      final List<dynamic> decoded = jsonDecode(entriesJson);
      for (final e in decoded) {
        if (e['category'] == categoryId) return true;
      }
    }
    return false;
  }

  Future<void> reassignCategory(String oldCategoryId, String newCategoryId) async {
    // When a custom category is deleted but still in use, reassign all entries
    // using the old category ID to a new category ID. This preserves data integrity
    // by updating all historical entries across all dates.
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('time_entries_')).toList();
    for (final key in keys) {
      final entriesJson = prefs.getString(key);
      if (entriesJson == null) continue;
      final List<dynamic> decoded = jsonDecode(entriesJson);
      bool changed = false;
      final updated = decoded.map((e) {
        if (e['category'] == oldCategoryId) {
          changed = true;
          return {...e, 'category': newCategoryId};
        }
        return e;
      }).toList();
      if (changed) {
        await prefs.setString(key, jsonEncode(updated));
      }
    }
  }
}
