import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/fade_options.dart';
import '../../../../core/services/local_storage_service.dart';

/// Device-level preferences: theme mood and the default fade timer.
abstract class SettingsRepository {
  Future<ThemeMode> themeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<FadeOption> defaultFade();
  Future<void> setDefaultFade(FadeOption fade);
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._storage);

  final LocalStorageService _storage;

  @override
  Future<ThemeMode> themeMode() async {
    final raw = await _storage.getString(AppConstants.themeKey);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) =>
      _storage.setString(AppConstants.themeKey, mode.name);

  @override
  Future<FadeOption> defaultFade() async {
    final raw = await _storage.getString(AppConstants.defaultFadeKey);
    return FadeOption.fromId(raw);
  }

  @override
  Future<void> setDefaultFade(FadeOption fade) =>
      _storage.setString(AppConstants.defaultFadeKey, fade.name);
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(ref.watch(localStorageProvider)),
);
