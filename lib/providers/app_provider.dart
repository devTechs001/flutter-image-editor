import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isDarkMode = true;
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;
  bool _onboardingComplete = false;
  Set<String> _favorites = {};
  Map<String, dynamic> _userSettings = {};
  bool _backendConnected = false;
  String? _lastBackendCheck;

  int get currentTabIndex => _currentTabIndex;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  bool get onboardingComplete => _onboardingComplete;
  Set<String> get favorites => _favorites;
  Map<String, dynamic> get userSettings => _userSettings;
  bool get backendConnected => _backendConnected;
  String? get lastBackendCheck => _lastBackendCheck;

  set currentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? true;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    _favorites = prefs.getStringList('favorites')?.toSet() ?? {};
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _savePreference('dark_mode', _isDarkMode);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    _savePreference('onboarding_complete', true);
    notifyListeners();
  }

  void resetOnboarding() {
    _onboardingComplete = false;
    _savePreference('onboarding_complete', false);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _savePreference('favorites', _favorites.toList());
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  void setBackendConnected(bool connected) {
    _backendConnected = connected;
    _lastBackendCheck = DateTime.now().toIso8601String();
    notifyListeners();
  }

  void updateSetting(String key, dynamic value) {
    _userSettings[key] = value;
    _savePreference('setting_$key', value.toString());
    notifyListeners();
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
    else if (value is String) prefs.setString(key, value);
    else if (value is int) prefs.setInt(key, value);
    else if (value is double) prefs.setDouble(key, value);
    else if (value is List) prefs.setStringList(key, value.cast<String>());
  }
}
