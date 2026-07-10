import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/fade_options.dart';
import '../../data/repositories/settings_repository.dart';

/// Theme + default-fade preferences, restored at launch.
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.defaultFade = FadeOption.m1,
  });

  final ThemeMode themeMode;
  final FadeOption defaultFade;

  SettingsState copyWith({ThemeMode? themeMode, FadeOption? defaultFade}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        defaultFade: defaultFade ?? this.defaultFade,
      );
}

class SettingsViewModel extends Notifier<SettingsState> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() {
    _restore();
    return const SettingsState();
  }

  Future<void> _restore() async {
    final mode = await _repo.themeMode();
    final fade = await _repo.defaultFade();
    state = SettingsState(themeMode: mode, defaultFade: fade);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repo.setThemeMode(mode);
  }

  Future<void> setDefaultFade(FadeOption fade) async {
    state = state.copyWith(defaultFade: fade);
    await _repo.setDefaultFade(fade);
  }
}

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);
