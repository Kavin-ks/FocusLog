import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local-only auth service.
/// Stores user data in SharedPreferences - no backend required.
class AuthService extends ChangeNotifier {
  static const _userDataKey = 'user_data';
  static const _isLoggedInKey = 'is_logged_in';
  static const _usersKey = 'registered_users';

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
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing users
    final usersJson = prefs.getString(_usersKey);
    final Map<String, dynamic> users = usersJson != null 
        ? jsonDecode(usersJson) as Map<String, dynamic>
        : {};
    
    // Check if email already exists
    if (users.containsKey(email)) {
      return 'This email is already in use.';
    }
    
    // Register user
    users[email] = {
      'name': name,
      'email': email,
      'password': password, // In real app, hash this
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    
    // Auto login after signup
    await _setLoggedIn(name, email);
    return null; // success
  }

  Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing users
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) {
      return 'Invalid email or password.';
    }
    
    final Map<String, dynamic> users = jsonDecode(usersJson) as Map<String, dynamic>;
    
    // Check credentials
    if (!users.containsKey(email)) {
      return 'Invalid email or password.';
    }
    
    final user = users[email] as Map<String, dynamic>;
    if (user['password'] != password) {
      return 'Invalid email or password.';
    }
    
    // Login success
    await _setLoggedIn(user['name'] as String, email);
    return null; // success
  }

  Future<String?> logout() async {
    await _clearCache();
    return null; // success
  }

  Future<void> _setLoggedIn(String name, String email) async {
    _userData = {
      'name': name,
      'email': email,
      'entries': [],
      'categories': [],
      'reflections': [],
    };
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(_userData));
    await prefs.setBool(_isLoggedInKey, true);

    notifyListeners();
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
