
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Single shared instance with AndroidOptions to reduce NotInitializedError on first launch
late final FlutterSecureStorage _secureStorage = () {
  if (Platform.isAndroid) {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: true),
    );
  }
  return const FlutterSecureStorage();
}();

class SecureStorage {
  static FlutterSecureStorage get _storage => _secureStorage;

  static Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

// Adapter for Supabase Persistence (uses single _secureStorage instance)
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return await _secureStorage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(key: supabasePersistSessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: supabasePersistSessionKey);
  }
}
