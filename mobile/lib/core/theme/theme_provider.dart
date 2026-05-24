import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/database/local_cache.dart';

// StateNotifier to manage dark/light modes dynamically
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(LocalCache.isDarkMode() ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      LocalCache.setDarkMode(true);
    } else {
      state = ThemeMode.light;
      LocalCache.setDarkMode(false);
    }
  }
}

// Global Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
