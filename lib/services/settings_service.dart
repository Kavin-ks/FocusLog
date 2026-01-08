import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_entry.dart';

class AppSettings {
  final int entriesPerPage;
  final bool autoSplitCrossMidnight;
  final List<ActivityCategory> customCategories;

  AppSettings({required this.entriesPerPage, required this.autoSplitCrossMidnight, required this.customCategories});

  factory AppSettings.defaults() => AppSettings(entriesPerPage: 50, autoSplitCrossMidnight: true, customCategories: []);

  Map<String, dynamic> toJson() => {
        'entriesPerPage': entriesPerPage,
        'autoSplitCrossMidnight': autoSplitCrossMidnight,
        'customCategories': customCategories.map((c) => c.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final entriesPerPage = (json['entriesPerPage'] is int) 
        ? json['entriesPerPage'] as int 
        : int.tryParse('${json['entriesPerPage']}') ?? 50;
    
    final autoSplitCrossMidnight = json['autoSplitCrossMidnight'] == true;
    
    final customCategories = (json['customCategories'] as List<dynamic>?)?.map((c) {
      try {
        return ActivityCategory.fromJson(c as Map<String, dynamic>);
      } catch (_) {
        return null; // Skip invalid categories
      }
    }).where((c) => c != null).cast<ActivityCategory>().toList() ?? [];
    
    return AppSettings(
      entriesPerPage: entriesPerPage.clamp(5, 1000),
      autoSplitCrossMidnight: autoSplitCrossMidnight,
      customCategories: customCategories,
    );
  }
}

class SettingsService {
  static const String key = 'app_settings_v2'; // Version bump for improved category handling
  static const String legacyKey = 'app_settings_v1'; // Keep for migration

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try current version first
    String? settingsJson = prefs.getString(key);
    
    // If not found, try legacy version for migration
    if (settingsJson == null) {
      settingsJson = prefs.getString(legacyKey);
      if (settingsJson != null) {
        // Migrate to new version: parse legacy data and save with new key
        // This ensures users upgrading from older versions don't lose settings
        try {
          final Map<String, dynamic> decoded = jsonDecode(settingsJson);
          final settings = AppSettings.fromJson(decoded);
          // Save with new version
          await saveSettings(settings);
          // Clean up old key to avoid confusion
          await prefs.remove(legacyKey);
        } catch (_) {
          // Migration failed, fall back to defaults
          settingsJson = null;
        }
      }
    }
    
    if (settingsJson == null) return AppSettings.defaults();
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(settingsJson);
      return AppSettings.fromJson(decoded);
    } catch (_) {
      // If parsing fails, attempt recovery: try to salvage valid categories
      // This prevents data loss if only part of the settings JSON is corrupted
      try {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        final customCategories = (decoded['customCategories'] as List<dynamic>?)?.map((c) {
          try {
            return ActivityCategory.fromJson(c as Map<String, dynamic>);
          } catch (_) {
            return null; // Skip invalid categories
          }
        }).where((c) => c != null).cast<ActivityCategory>().toList() ?? [];
        
        return AppSettings(
          entriesPerPage: 50,
          autoSplitCrossMidnight: true,
          customCategories: customCategories,
        );
      } catch (_) {
        return AppSettings.defaults();
      }
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(settings.toJson()));
  }
}
