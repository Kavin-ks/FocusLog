enum ActivityCategory {
  study,
  work,
  rest,
  scroll,
  other,
}

extension ActivityCategoryExtension on ActivityCategory {
  String get displayName {
    switch (this) {
      case ActivityCategory.study:
        return 'Study';
      case ActivityCategory.work:
        return 'Work';
      case ActivityCategory.rest:
        return 'Rest';
      case ActivityCategory.scroll:
        return 'Scroll';
      case ActivityCategory.other:
        return 'Other';
    }
  }
}

class TimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String activityName;
  final ActivityCategory category;

  TimeEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.activityName,
    required this.category,
  });

  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'activityName': activityName,
      'category': category.name,
    };
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      activityName: json['activityName'] as String,
      category: ActivityCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ActivityCategory.other,
      ),
    );
  }

  TimeEntry copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? activityName,
    ActivityCategory? category,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activityName: activityName ?? this.activityName,
      category: category ?? this.category,
    );
  }
}

