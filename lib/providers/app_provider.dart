import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isDarkMode = true;
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;

  int get currentTabIndex => _currentTabIndex;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  set currentTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
