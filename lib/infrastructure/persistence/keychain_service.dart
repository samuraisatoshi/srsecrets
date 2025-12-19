/// Keychain Service
///
/// Platform-native secure storage using iOS Keychain and Android Keystore.
/// Provides hardware-backed encryption for sensitive authentication data.
library;

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interface for platform keychain operations
abstract class IKeychainService {
  /// Store a value securely in the platform keychain
  Future<void> write(String key, String value);

  /// Read a value from the platform keychain
  Future<String?> read(String key);

  /// Delete a value from the platform keychain
  Future<void> delete(String key);

  /// Delete all values from the platform keychain
  Future<void> deleteAll();

  /// Check if a key exists in the platform keychain
  Future<bool> containsKey(String key);

  /// Store a map as JSON in the keychain
  Future<void> writeMap(String key, Map<String, dynamic> data);

  /// Read a map from JSON in the keychain
  Future<Map<String, dynamic>?> readMap(String key);
}

/// Flutter Secure Storage implementation of keychain service
///
/// Uses platform-native secure storage:
/// - iOS: Keychain Services (hardware-backed on devices with Secure Enclave)
/// - Android: EncryptedSharedPreferences with Android Keystore
/// - macOS: Keychain Services
/// - Linux: libsecret
/// - Windows: Windows Credential Manager
class FlutterKeychainService implements IKeychainService {
  static const String _logName = 'FlutterKeychainService';

  final FlutterSecureStorage _storage;

  FlutterKeychainService({FlutterSecureStorage? storage})
      : _storage = storage ?? _createSecureStorage();

  /// Create secure storage with platform-optimized options
  static FlutterSecureStorage _createSecureStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        sharedPreferencesName: 'srsecrets_secure_prefs',
        preferencesKeyPrefix: 'srs_',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        accountName: 'srsecrets',
      ),
      mOptions: MacOsOptions(
        accountName: 'srsecrets',
        groupId: 'srsecrets',
      ),
    );
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      developer.log('Wrote key: $key', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR writing to keychain',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to write to keychain: $e');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      developer.log('Read key: $key, exists: ${value != null}', name: _logName);
      return value;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR reading from keychain',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to read from keychain: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      developer.log('Deleted key: $key', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR deleting from keychain',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to delete from keychain: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      developer.log('Deleted all keys', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR deleting all from keychain',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to delete all from keychain: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final exists = await _storage.containsKey(key: key);
      return exists;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR checking key existence',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to check key existence: $e');
    }
  }

  @override
  Future<void> writeMap(String key, Map<String, dynamic> data) async {
    final jsonString = json.encode(data);
    await write(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> readMap(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR parsing JSON from keychain',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw KeychainException('Failed to parse keychain data: $e');
    }
  }
}

/// Exception thrown when keychain operations fail
class KeychainException implements Exception {
  const KeychainException(this.message);
  final String message;

  @override
  String toString() => 'KeychainException: $message';
}
