/// Secure Storage Repository Implementation
///
/// Provides secure file-based storage for PIN authentication data.
/// Implements air-gapped design with local encrypted storage only.
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../services/pin_service.dart';
import '../models/pin_hash.dart';
import '../models/auth_attempt.dart';
import '../../crypto/random/secure_random.dart';

/// File-based secure storage for authentication data
/// Uses application documents directory with file-level security
class SecureStorageRepository implements IPinStorageRepository {
  /// Filename for PIN hash storage
  static const String _pinHashFile = 'pin_hash.dat';

  /// Filename for attempt history storage
  static const String _attemptHistoryFile = 'auth_attempts.dat';

  /// Directory for secure storage
  Directory? _secureDirectory;

  /// Initialize secure storage directory
  Future<void> _initializeDirectory() async {
    if (_secureDirectory != null) return;

    try {
      developer.log(
        'Initializing secure storage directory',
        name: 'SecureStorageRepository',
      );

      // Use application support directory which is cleared on app uninstall
      // On iOS: Library/Application Support (cleared on uninstall)
      // On Android: files directory (cleared on uninstall)
      Directory appDir;

      if (Platform.isIOS || Platform.isMacOS) {
        // Use app support directory which is cleared on uninstall
        appDir = await getApplicationSupportDirectory();
      } else {
        // For Android and other platforms, use app documents directory
        // Android clears this on uninstall by default
        appDir = await getApplicationDocumentsDirectory();
      }

      _secureDirectory = Directory('${appDir.path}/secure_auth');

      developer.log(
        'Secure directory path: ${_secureDirectory!.path}',
        name: 'SecureStorageRepository',
      );

      // Create directory if it doesn't exist
      if (!await _secureDirectory!.exists()) {
        await _secureDirectory!.create(recursive: true);

        developer.log(
          'Created secure directory',
          name: 'SecureStorageRepository',
        );

        // Set restrictive permissions (Unix/Linux/macOS)
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['700', _secureDirectory!.path]);
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'CRITICAL: Failed to initialize secure storage',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to initialize secure storage: $e');
    }
  }

  /// Get file path for secure storage
  Future<String> _getSecureFilePath(String filename) async {
    await _initializeDirectory();
    return '${_secureDirectory!.path}/$filename';
  }

  @override
  Future<PinHash?> loadPinHash() async {
    try {
      developer.log(
        'Loading PIN hash',
        name: 'SecureStorageRepository',
      );

      // First, attempt to migrate old data if needed
      try {
        await _migrateOldData();
      } catch (e) {
        developer.log(
          'Migration failed, continuing with load attempt',
          name: 'SecureStorageRepository',
          error: e,
        );
      }

      String filePath = await _getSecureFilePath(_pinHashFile);
      File file = File(filePath);

      if (!await file.exists()) {
        developer.log(
          'PIN hash file does not exist at: $filePath',
          name: 'SecureStorageRepository',
        );
        return null;
      }

      developer.log(
        'PIN hash file exists, reading content from: $filePath',
        name: 'SecureStorageRepository',
      );

      // Read and decrypt file content
      String encryptedContent = await file.readAsString();
      Map<String, dynamic> data = _decryptData(encryptedContent);

      developer.log(
        'Successfully loaded and decrypted PIN hash',
        name: 'SecureStorageRepository',
      );

      return PinHash.fromMap(data);

    } catch (e, stackTrace) {
      developer.log(
        'CRITICAL ERROR loading PIN hash',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );

      // Check if it's a "file not found" scenario (return null)
      if (e is FileSystemException) {
        developer.log(
          'FileSystemException - treating as PIN not set',
          name: 'SecureStorageRepository',
        );
        return null;
      }

      // For other errors, still return null but log severity
      developer.log(
        'Non-filesystem error occurred - data may be corrupted',
        name: 'SecureStorageRepository',
      );
      return null;
    }
  }

  @override
  Future<void> savePinHash(PinHash pinHash) async {
    try {
      developer.log(
        'Saving PIN hash',
        name: 'SecureStorageRepository',
      );

      String filePath = await _getSecureFilePath(_pinHashFile);
      File file = File(filePath);

      // Encrypt and save data
      Map<String, dynamic> data = pinHash.toMap();
      String encryptedContent = _encryptData(data);

      await file.writeAsString(encryptedContent);

      developer.log(
        'PIN hash saved successfully to: $filePath',
        name: 'SecureStorageRepository',
      );

      // Set restrictive file permissions
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['600', filePath]);
        developer.log(
          'File permissions set to 600',
          name: 'SecureStorageRepository',
        );
      }

    } catch (e, stackTrace) {
      developer.log(
        'ERROR saving PIN hash',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to save PIN hash: $e');
    }
  }

  @override
  Future<void> deletePinHash() async {
    try {
      developer.log(
        'Deleting PIN hash',
        name: 'SecureStorageRepository',
      );

      String filePath = await _getSecureFilePath(_pinHashFile);
      File file = File(filePath);

      if (await file.exists()) {
        // Securely overwrite file before deletion
        await _secureDeleteFile(file);

        developer.log(
          'Successfully deleted PIN hash',
          name: 'SecureStorageRepository',
        );
      } else {
        developer.log(
          'PIN hash file does not exist, nothing to delete',
          name: 'SecureStorageRepository',
        );
      }

    } catch (e, stackTrace) {
      developer.log(
        'ERROR deleting PIN hash',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to delete PIN hash: $e');
    }
  }

  @override
  Future<AuthAttemptHistory> loadAttemptHistory() async {
    try {
      String filePath = await _getSecureFilePath(_attemptHistoryFile);
      File file = File(filePath);

      if (!await file.exists()) {
        return AuthAttemptHistory([]);
      }

      // Read and decrypt file content
      String encryptedContent = await file.readAsString();
      Map<String, dynamic> data = _decryptData(encryptedContent);

      return AuthAttemptHistory.fromMap(data);

    } catch (e) {
      // Return empty history on any error
      developer.log(
        'Failed to load attempt history, returning empty',
        name: 'SecureStorageRepository',
        error: e,
      );
      return AuthAttemptHistory([]);
    }
  }

  @override
  Future<void> saveAttemptHistory(AuthAttemptHistory history) async {
    try {
      String filePath = await _getSecureFilePath(_attemptHistoryFile);
      File file = File(filePath);

      // Encrypt and save data
      Map<String, dynamic> data = history.toMap();
      String encryptedContent = _encryptData(data);

      await file.writeAsString(encryptedContent);

      // Set restrictive file permissions
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['600', filePath]);
      }

    } catch (e, stackTrace) {
      developer.log(
        'ERROR saving attempt history',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to save attempt history: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      developer.log(
        'Clearing all authentication data',
        name: 'SecureStorageRepository',
      );

      await deletePinHash();

      String attemptFilePath = await _getSecureFilePath(_attemptHistoryFile);
      File attemptFile = File(attemptFilePath);

      if (await attemptFile.exists()) {
        await _secureDeleteFile(attemptFile);
      }

      developer.log(
        'Successfully cleared all authentication data',
        name: 'SecureStorageRepository',
      );

    } catch (e, stackTrace) {
      developer.log(
        'ERROR clearing all authentication data',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to clear all authentication data: $e');
    }
  }

  /// Simple XOR-based encryption for file storage
  /// Note: This provides basic obfuscation, not cryptographic security
  /// In production, use proper encryption libraries
  String _encryptData(Map<String, dynamic> data) {
    try {
      // Convert to JSON
      String jsonData = json.encode(data);
      Uint8List dataBytes = Uint8List.fromList(utf8.encode(jsonData));

      // Generate simple XOR key based on device characteristics
      Uint8List key = _generateSimpleKey();

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
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt XOR-encrypted data
  Map<String, dynamic> _decryptData(String encryptedContent) {
    try {
      // Decode from Base64
      Uint8List encrypted = base64.decode(encryptedContent);

      // Generate same XOR key
      Uint8List key = _generateSimpleKey();

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
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Generate simple XOR key based on device characteristics
  /// This is basic obfuscation, not secure encryption
  Uint8List _generateSimpleKey() {
    // Use a combination of platform-specific values for key generation
    String keyBase = Platform.operatingSystem +
                     Platform.operatingSystemVersion +
                     'srsecrets_auth_key';

    // Hash the key base to create consistent key
    List<int> keyBytes = utf8.encode(keyBase);

    // Extend to 256 bytes for better XOR coverage
    Uint8List key = Uint8List(256);
    for (int i = 0; i < key.length; i++) {
      key[i] = keyBytes[i % keyBytes.length];
    }

    return key;
  }

  /// Securely delete a file by overwriting before deletion
  Future<void> _secureDeleteFile(File file) async {
    try {
      // Get file size
      int fileSize = await file.length();

      // Overwrite with random data 3 times
      SecureRandom secureRandom = SecureRandom.instance;

      for (int pass = 0; pass < 3; pass++) {
        Uint8List randomData = secureRandom.nextBytes(fileSize);
        await file.writeAsBytes(randomData, flush: true);
      }

      // Final overwrite with zeros
      Uint8List zeros = Uint8List(fileSize);
      await file.writeAsBytes(zeros, flush: true);

      // Delete the file
      await file.delete();

    } catch (e) {
      // If secure deletion fails, still try regular deletion
      try {
        await file.delete();
      } catch (deleteError) {
        throw Exception('Failed to delete file securely: $e, $deleteError');
      }
    }
  }

  /// Check if storage is properly initialized and accessible
  Future<bool> isAvailable() async {
    try {
      await _initializeDirectory();
      return await _secureDirectory!.exists();
    } catch (e) {
      developer.log(
        'Storage availability check failed',
        name: 'SecureStorageRepository',
        error: e,
      );
      return false;
    }
  }

  /// Get storage statistics for diagnostics
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      await _initializeDirectory();

      String pinHashPath = await _getSecureFilePath(_pinHashFile);
      String attemptPath = await _getSecureFilePath(_attemptHistoryFile);

      File pinHashFile = File(pinHashPath);
      File attemptFile = File(attemptPath);

      bool pinHashExists = await pinHashFile.exists();
      bool attemptHistoryExists = await attemptFile.exists();

      developer.log(
        'Storage info - PIN exists: $pinHashExists, Attempts exists: $attemptHistoryExists',
        name: 'SecureStorageRepository',
      );

      return {
        'storageDirectory': _secureDirectory!.path,
        'pinHashExists': pinHashExists,
        'pinHashSize': pinHashExists ? await pinHashFile.length() : 0,
        'pinHashPath': pinHashPath,
        'attemptHistoryExists': attemptHistoryExists,
        'attemptHistorySize': attemptHistoryExists ? await attemptFile.length() : 0,
        'attemptHistoryPath': attemptPath,
        'isAvailable': true,
      };

    } catch (e, stackTrace) {
      developer.log(
        'ERROR getting storage info',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'error': 'Failed to get storage info: $e',
        'isAvailable': false,
      };
    }
  }

  /// Diagnostic method to help troubleshoot storage issues
  /// Use this when debugging PIN authentication problems
  Future<Map<String, dynamic>> runDiagnostics() async {
    developer.log(
      '=== Running Storage Diagnostics ===',
      name: 'SecureStorageRepository',
    );

    Map<String, dynamic> diagnostics = {};

    try {
      // Check directory initialization
      diagnostics['directoryInitialized'] = _secureDirectory != null;

      // Check storage availability
      diagnostics['storageAvailable'] = await isAvailable();

      // Get storage info
      Map<String, dynamic> storageInfo = await getStorageInfo();
      diagnostics.addAll(storageInfo);

      // Try to load PIN hash
      try {
        PinHash? pinHash = await loadPinHash();
        diagnostics['pinHashLoadSuccess'] = true;
        diagnostics['pinHashIsNull'] = pinHash == null;
        if (pinHash != null) {
          diagnostics['pinHashIterations'] = pinHash.iterations;
          diagnostics['pinHashNeedsUpgrade'] = pinHash.needsUpgrade();
        }
      } catch (e) {
        diagnostics['pinHashLoadSuccess'] = false;
        diagnostics['pinHashLoadError'] = e.toString();
      }

      // Log diagnostics
      developer.log(
        'Diagnostics complete',
        name: 'SecureStorageRepository',
      );
      diagnostics.forEach((key, value) {
        developer.log(
          '$key: $value',
          name: 'SecureStorageRepository.Diagnostics',
        );
      });

    } catch (e, stackTrace) {
      developer.log(
        'Diagnostics failed',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      diagnostics['diagnosticsError'] = e.toString();
    }

    return diagnostics;
  }

  /// Migrate data from old storage location if it exists
  /// This handles the case where PIN data was stored in Documents directory
  Future<void> _migrateOldData() async {
    try {
      developer.log(
        'Checking for data migration',
        name: 'SecureStorageRepository',
      );

      // Check for old storage location (Documents directory)
      Directory oldDocDir = await getApplicationDocumentsDirectory();
      Directory oldSecureDir = Directory('${oldDocDir.path}/secure_auth');

      if (await oldSecureDir.exists()) {
        developer.log(
          'Old storage directory found: ${oldSecureDir.path}',
          name: 'SecureStorageRepository',
        );

        // Old data exists, check if we need to migrate
        File oldPinFile = File('${oldSecureDir.path}/$_pinHashFile');
        File oldAttemptFile = File('${oldSecureDir.path}/$_attemptHistoryFile');

        // Check if new location already has data
        String newPinPath = await _getSecureFilePath(_pinHashFile);
        File newPinFile = File(newPinPath);

        // Only migrate if new location doesn't have PIN data
        if (await oldPinFile.exists() && !await newPinFile.exists()) {
          developer.log(
            'Migrating PIN data from old location',
            name: 'SecureStorageRepository',
          );

          // Copy PIN hash file
          await oldPinFile.copy(newPinPath);
          developer.log(
            'PIN hash migrated to: $newPinPath',
            name: 'SecureStorageRepository',
          );

          // Copy attempt history if exists
          if (await oldAttemptFile.exists()) {
            String newAttemptPath = await _getSecureFilePath(_attemptHistoryFile);
            await oldAttemptFile.copy(newAttemptPath);
            developer.log(
              'Attempt history migrated',
              name: 'SecureStorageRepository',
            );
          }

          developer.log(
            'Migration completed successfully',
            name: 'SecureStorageRepository',
          );
        } else {
          developer.log(
            'No migration needed (new location has data or old location empty)',
            name: 'SecureStorageRepository',
          );
        }

        // Clean up old directory after successful migration
        await _cleanupOldDirectory(oldSecureDir);
      } else {
        developer.log(
          'No old storage directory found - no migration needed',
          name: 'SecureStorageRepository',
        );
      }
    } catch (e, stackTrace) {
      // Migration failed, but don't break the app
      // User will need to set up PIN again
      developer.log(
        'ERROR during migration',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - allow app to continue with fresh PIN setup
    }
  }

  /// Clean up old storage directory
  Future<void> _cleanupOldDirectory(Directory oldDir) async {
    try {
      if (await oldDir.exists()) {
        developer.log(
          'Cleaning up old storage directory',
          name: 'SecureStorageRepository',
        );

        // Securely delete all files in old directory
        await for (var entity in oldDir.list()) {
          if (entity is File) {
            await _secureDeleteFile(entity);
          }
        }
        // Remove the directory itself
        await oldDir.delete(recursive: true);

        developer.log(
          'Old directory cleaned up',
          name: 'SecureStorageRepository',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to cleanup old directory',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Force clear all PIN data from all possible storage locations
  /// This is useful for debugging or when user needs a complete reset
  Future<void> forceClearAllStorageLocations() async {
    try {
      developer.log(
        'Force clearing all storage locations',
        name: 'SecureStorageRepository',
      );

      // Clear current storage location
      await clearAll();

      // Clear old Documents directory location
      Directory oldDocDir = await getApplicationDocumentsDirectory();
      Directory oldSecureDir = Directory('${oldDocDir.path}/secure_auth');
      if (await oldSecureDir.exists()) {
        await _cleanupOldDirectory(oldSecureDir);
      }

      developer.log(
        'All storage locations cleared',
        name: 'SecureStorageRepository',
      );

      // Clear any other potential legacy locations
      // (Add more locations here if storage location changes in future)

    } catch (e, stackTrace) {
      developer.log(
        'ERROR force clearing all storage locations',
        name: 'SecureStorageRepository',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to force clear all storage locations: $e');
    }
  }
}
