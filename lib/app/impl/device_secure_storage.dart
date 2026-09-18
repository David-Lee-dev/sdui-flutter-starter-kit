import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sdui_engine/sdui_engine.dart';

/// App-owned [SecureStorage] — the platform keystore via
/// flutter_secure_storage (iOS Keychain / Android Keystore-encrypted prefs).
///
/// Backs the engine's `secure_storage` driver, so templates can persist
/// tokens and other secrets without ever seeing the platform APIs.
class DeviceSecureStorage implements SecureStorage {
  const DeviceSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
