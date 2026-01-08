import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int entriesPerPage;
  final bool autoSplitCrossMidnight;

  AppSettings({required this.entriesPerPage, required this.autoSplitCrossMidnight});

  factory AppSettings.defaults() => AppSettings(entriesPerPage: 50, autoSplitCrossMidnight: true);

  Map<String, dynamic> toJson() => {
        'entriesPerPage': entriesPerPage,
        'autoSplitCrossMidnight': autoSplitCrossMidnight,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        entriesPerPage: (json['entriesPerPage'] is int) ? json['entriesPerPage'] as int : int.tryParse('${json['entriesPerPage']}') ?? 50,
        autoSplitCrossMidnight: json['autoSplitCrossMidnight'] == true,
      );
}

class SettingsService {
  static const String key = 'app_settings_v1';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(key);
    if (s == null) return AppSettings.defaults();
    try {
      final Map<String, dynamic> decoded = jsonDecode(s);
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(settings.toJson()));
  }
}
