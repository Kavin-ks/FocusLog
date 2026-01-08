import 'dart:ui';

class ActivityCategory {
  final String id;
  final String displayName;
  final bool isBuiltIn;
  final Color? color;

  const ActivityCategory(this.id, this.displayName, {this.isBuiltIn = false, this.color});

  // Built-in categories with default muted colors
  static final study = ActivityCategory('study', 'Study', isBuiltIn: true, color: const Color(0xFF4CAF50));
  static final work = ActivityCategory('work', 'Work', isBuiltIn: true, color: const Color(0xFF2196F3));
  static final rest = ActivityCategory('rest', 'Rest', isBuiltIn: true, color: const Color(0xFFFF9800));
  static final scroll = ActivityCategory('scroll', 'Scroll', isBuiltIn: true, color: const Color(0xFF9C27B0));
  static final other = ActivityCategory('other', 'Other', isBuiltIn: true, color: const Color(0xFF757575));

  static List<ActivityCategory> get builtInCategories => [study, work, rest, scroll, other];

  @override
  bool operator ==(Object other) => other is ActivityCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isBuiltIn': isBuiltIn,
        'color': color?.toARGB32(),
      };

  factory ActivityCategory.fromJson(Map<String, dynamic> json) =>
      ActivityCategory(
        json['id'],
        json['displayName'],
        isBuiltIn: json['isBuiltIn'] ?? false,
        color: json['color'] != null ? Color(json['color']) : null,
      );
}


enum EnergyLevel { low, neutral, high }

extension EnergyLevelExtension on EnergyLevel {
  String get displayName {
    switch (this) {
      case EnergyLevel.low:
        return 'Low energy';
      case EnergyLevel.neutral:
        return 'Neutral';
      case EnergyLevel.high:
        return 'High energy';
    }
  }
}

enum IntentTag { intentional, unintentional }

extension IntentTagExtension on IntentTag {
  String get displayName {
    switch (this) {
      case IntentTag.intentional:
        return 'Intentional';
      case IntentTag.unintentional:
        return 'Unintentional';
    }
  }
}

class TimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String activityName;
  final ActivityCategory category;
  final EnergyLevel? energyLevel; // optional - nullable to preserve backward compatibility
  final IntentTag? intent; // optional, neutral intent tag

  TimeEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.activityName,
    required this.category,
    this.energyLevel,
    this.intent,
  });

  /// Duration in whole minutes. This is normalized to be non-negative;
  /// if `endTime` was (unexpectedly) before `startTime` the getter will
  /// return 0 rather than a negative duration.
  int get durationMinutes {
    final mins = endTime.difference(startTime).inMinutes;
    return mins > 0 ? mins : 0;
  }

  /// Returns a normalized copy of this entry.
  ///
  /// Normalization rules:
  /// - If `endTime` is before `startTime` we assume it crossed midnight and
  ///   move `endTime` forward by one day.
  TimeEntry normalized() {
    var s = startTime;
    var e = endTime;
    if (e.isBefore(s)) {
      e = e.add(const Duration(days: 1));
    }
    return copyWith(startTime: s, endTime: e);
  }

  Map<String, dynamic> toJson() {
    final n = normalized();
    return {
      'id': id,
      'startTime': n.startTime.toIso8601String(),
      'endTime': n.endTime.toIso8601String(),
      'activityName': activityName,
      'category': category.id,
      'energy': energyLevel?.name, // may be null
      'intent': intent?.name, // may be null
    };
  }

  /// Parses a JSON map into a [TimeEntry].
  ///
  /// Normalization rules applied here:
  /// - If `endTime` is earlier than `startTime` we interpret the entry as
 
  /// - Optional fields (`energy`, `intent`) are treated as nullable. If the
  ///   stored value is missing or invalid we preserve them as `null` instead
  
  factory TimeEntry.fromJson(Map<String, dynamic> json, [List<ActivityCategory>? customCategories]) {
    final id = json['id'] as String;

    final start = DateTime.parse(json['startTime'] as String);
    var end = DateTime.parse(json['endTime'] as String);

    // If end is before start, assume it was intended as the next day.
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final categoryId = json['category'] as String;
    ActivityCategory category;
    try {
      category = ActivityCategory.builtInCategories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      try {
        category = customCategories!.firstWhere((c) => c.id == categoryId);
      } catch (_) {
        category = ActivityCategory(categoryId, categoryId);
      }
    }

    EnergyLevel? energyLevel;
    if (json.containsKey('energy') && json['energy'] != null) {
      final energyName = json['energy'] as String;
      try {
        energyLevel = EnergyLevel.values.firstWhere((e) => e.name == energyName);
      } catch (_) {
        // Unknown/invalid energy value: treat as missing (null).
        energyLevel = null;
      }
    } else {
      energyLevel = null;
    }

    IntentTag? intent;
    if (json.containsKey('intent') && json['intent'] != null) {
      final intentName = json['intent'] as String;
      try {
        intent = IntentTag.values.firstWhere((i) => i.name == intentName);
      } catch (_) {
        intent = null;
      }
    } else {
      intent = null;
    }

    return TimeEntry(
      id: id,
      startTime: start,
      endTime: end,
      activityName: json['activityName'] as String,
      category: category,
      energyLevel: energyLevel,
      intent: intent,
    );
  }

  TimeEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? activityName,
    ActivityCategory? category,
    EnergyLevel? energyLevel,
    IntentTag? intent,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activityName: activityName ?? this.activityName,
      category: category ?? this.category,
      energyLevel: energyLevel ?? this.energyLevel,
      intent: intent ?? this.intent,
    );
  }
}

/* Design notes (key decisions)
 - Cross-midnight normalization: entries where `endTime` parses earlier than
   `startTime` are interpreted as having crossed midnight. We normalize by
   advancing `endTime` by one day. This preserves intended durations for
   entries saved without an explicit next-day date (common with manual entry
   workflows or older app versions).
 - Optional fields: `energyLevel` and `intent` are intentionally nullable.
   When reading stored data we treat missing or invalid values as `null`
   rather than inventing defaults; this avoids misleading analytics and keeps
   migration simple.
 - Persistence consistency: `toJson()` emits the normalized representation so
   stored JSON follows a consistent structure. Consumers should prefer loading
   via `fromJson()` and may persist normalized objects back to storage.
 - Duration safety: `durationMinutes` never returns negative values; if an
   unexpected ordering occurs we return 0 rather than a negative duration.
*/

