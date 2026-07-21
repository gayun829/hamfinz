import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    final value = _prefs;
    if (value == null) {
      throw StateError('StorageService not initialized');
    }
    return value;
  }

  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  String? getString(String key) => prefs.getString(key);

  Future<void> remove(String key) async {
    await prefs.remove(key);
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
