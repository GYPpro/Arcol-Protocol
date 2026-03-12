import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final ThemeMode themeMode;
  final Color seedColor;

  ThemeState({
    this.themeMode = ThemeMode.system,
    this.seedColor = Colors.blue,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const _themeModeKey = 'theme_mode';
  static const _seedColorKey = 'seed_color';

  ThemeNotifier() : super(ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final seedColorValue = prefs.getInt(_seedColorKey) ?? Colors.blue.toARGB32();
    
    state = ThemeState(
      themeMode: ThemeMode.values[themeModeIndex],
      seedColor: Color(seedColorValue),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    state = state.copyWith(seedColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

const List<Color> availableColors = [
  Colors.blue,
  Colors.purple,
  Colors.red,
  Colors.orange,
  Colors.green,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
  Colors.cyan,
  Colors.amber,
];
