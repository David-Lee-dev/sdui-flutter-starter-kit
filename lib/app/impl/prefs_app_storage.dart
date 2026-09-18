import 'dart:convert';

import 'package:sdui_engine/sdui_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-owned [AppStorage] — real device storage via shared_preferences.
///
/// The engine's `app_storage` driver reads synchronously, so the preferences
/// instance is loaded once at boot ([load]) and reads hit its in-memory
/// cache. Values are JSON-encoded under a namespaced key, so any
/// JSON-compatible value templates store round-trips unchanged.
class PrefsAppStorage implements AppStorage {
  PrefsAppStorage(this._prefs);

  static const _prefix = 'sdui.';

  /// Loads the device-backed store. Call once before `runApp`.
  static Future<PrefsAppStorage> load() async =>
      PrefsAppStorage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  Object? get(String key) {
    final raw = _prefs.getString('$_prefix$key');
    return raw == null ? null : jsonDecode(raw);
  }

  @override
  Future<void> set(String key, Object? value) async {
    if (value == null) {
      await _prefs.remove('$_prefix$key');
    } else {
      await _prefs.setString('$_prefix$key', jsonEncode(value));
    }
  }
}
