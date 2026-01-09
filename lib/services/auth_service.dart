import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Auth service that integrates with the backend API.
/// Handles authentication and caches user data locally.
class AuthService extends ChangeNotifier {
  static const _userDataKey = 'user_data';
  static const _isLoggedInKey = 'is_logged_in';

  static const String baseUrl = 'http://localhost:8080/api';

  Map<String, dynamic>? _userData;
  bool _isLoggedIn = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (_isLoggedIn) {
      final userDataJson = prefs.getString(_userDataKey);
      if (userDataJson != null) {
        _userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      }
    }
    notifyListeners();
  }

  Future<String?> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _handleLoginSuccess(data['user']);
        return null; // success
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        return error['error'] as String?;
      }
    } catch (e) {
      return 'Something went wrong. Please try again later.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _handleLoginSuccess(data['user']);
        return null; // success
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        return error['error'] as String?;
      }
    } catch (e) {
      return 'Something went wrong. Please try again later.';
    }
  }

  Future<String?> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await _clearCache();
        return null; // success
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        return error['error'] as String?;
      }
    } catch (e) {
      return 'Something went wrong. Please try again later.';
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> user) async {
    // Fetch user data
    final data = await _fetchUserData();
    if (data != null) {
      _userData = data;
      _isLoggedIn = true;

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(data));
      await prefs.setBool(_isLoggedInKey, true);

      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      // Fetch entries
      final entriesResponse = await http.get(Uri.parse('$baseUrl/entries'));
      if (entriesResponse.statusCode != 200) return null;

      // Fetch categories
      final categoriesResponse = await http.get(Uri.parse('$baseUrl/categories'));
      if (categoriesResponse.statusCode != 200) return null;

      // Fetch reflections
      final reflectionsResponse = await http.get(Uri.parse('$baseUrl/reflections'));
      if (reflectionsResponse.statusCode != 200) return null;

      final entries = jsonDecode(entriesResponse.body) as Map<String, dynamic>;
      final categories = jsonDecode(categoriesResponse.body) as Map<String, dynamic>;
      final reflections = jsonDecode(reflectionsResponse.body) as Map<String, dynamic>;

      return {
        'entries': entries['entries'],
        'categories': categories['categories'],
        'reflections': reflections['reflections'],
      };
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_isLoggedInKey);
    _userData = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // Get cached data
  List<dynamic> getCachedEntries() {
    return _userData?['entries'] as List<dynamic>? ?? [];
  }

  List<dynamic> getCachedCategories() {
    return _userData?['categories'] as List<dynamic>? ?? [];
  }

  List<dynamic> getCachedReflections() {
    return _userData?['reflections'] as List<dynamic>? ?? [];
  }
}
