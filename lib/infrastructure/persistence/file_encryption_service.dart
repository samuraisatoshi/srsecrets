/// File Encryption Service
///
/// Provides file-level encryption for secure storage.
/// Implements basic XOR obfuscation for local file protection.
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

/// Interface for file encryption operations
abstract class IFileEncryptionService {
  /// Encrypt data map to string for storage
  String encrypt(Map<String, dynamic> data);

  /// Decrypt string back to data map
  Map<String, dynamic> decrypt(String encryptedContent);
}

/// XOR-based file encryption service
///
/// Note: This provides basic obfuscation, not cryptographic security.
/// For production with sensitive data, use proper encryption libraries.
class XorFileEncryptionService implements IFileEncryptionService {
  static const String _logName = 'XorFileEncryptionService';

  @override
  String encrypt(Map<String, dynamic> data) {
    try {
      // Convert to JSON
      String jsonData = json.encode(data);
      Uint8List dataBytes = Uint8List.fromList(utf8.encode(jsonData));

      // Generate XOR key
      Uint8List key = _generateKey();

      // XOR encryption
      Uint8List encrypted = Uint8List(dataBytes.length);
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted[i] = dataBytes[i] ^ key[i % key.length];
      }

      // Base64 encode for storage
      return base64.encode(encrypted);
    } catch (e, stackTrace) {
      developer.log(
        'ERROR encrypting data',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  @override
  Map<String, dynamic> decrypt(String encryptedContent) {
    try {
      // Decode from Base64
      Uint8List encrypted = base64.decode(encryptedContent);

      // Generate same XOR key
      Uint8List key = _generateKey();

      // XOR decryption
      Uint8List decrypted = Uint8List(encrypted.length);
      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ key[i % key.length];
      }

      // Convert back to JSON
      String jsonData = utf8.decode(decrypted);
      return json.decode(jsonData) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      developer.log(
        'ERROR decrypting data - data may be corrupted',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Generate XOR key based on device characteristics
  Uint8List _generateKey() {
    // Use platform-specific values for key generation
    String keyBase = Platform.operatingSystem +
        Platform.operatingSystemVersion +
        'srsecrets_auth_key';

    // Hash the key base
    List<int> keyBytes = utf8.encode(keyBase);

    // Extend to 256 bytes for better XOR coverage
    Uint8List key = Uint8List(256);
    for (int i = 0; i < key.length; i++) {
      key[i] = keyBytes[i % keyBytes.length];
    }

    return key;
  }
}

/// Exception thrown when encryption/decryption fails
class EncryptionException implements Exception {
  const EncryptionException(this.message);
  final String message;

  @override
  String toString() => 'EncryptionException: $message';
}
