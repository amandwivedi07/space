import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin async wrapper over SharedPreferences with JSON helpers.
class LocalStorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<String?> getString(String key) async =>
      (await _instance).getString(key);

  Future<void> setString(String key, String value) async =>
      (await _instance).setString(key, value);

  Future<bool?> getBool(String key) async => (await _instance).getBool(key);

  Future<void> setBool(String key, bool value) async =>
      (await _instance).setBool(key, value);

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) =>
      setString(key, jsonEncode(value));

  Future<void> remove(String key) async => (await _instance).remove(key);
}

final localStorageProvider =
    Provider<LocalStorageService>((ref) => LocalStorageService());
