/// Secure Storage Repository Implementation
///
/// Provides secure storage for PIN authentication data using:
/// - Platform Keychain (iOS Keychain / Android Keystore) for PIN hash
/// - File-based storage with secure deletion for attempt history
///
/// Infrastructure layer implementation of IPinStorageRepository.
library;

import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import '../../domains/auth/services/pin_service.dart';
import '../../domains/auth/models/pin_hash.dart';
import '../../domains/auth/models/auth_attempt.dart';
import '../../domains/crypto/random/secure_random.dart';
import 'file_encryption_service.dart';
import 'keychain_service.dart';

/// Secure storage repository using platform keychain for sensitive data
class SecureStorageRepository implements IPinStorageRepository {
  static const String _logName = 'SecureStorageRepository';
  static const String _pinHashKey = 'srsecrets_pin_hash';
  static const String _pinHashFile = 'pin_hash.dat'; // Legacy, for migration
  static const String _attemptHistoryFile = 'auth_attempts.dat';

  final IKeychainService _keychainService;
  final IFileEncryptionService _encryptionService;
  Directory? _secureDirectory;
  bool _migrationChecked = false;

  SecureStorageRepository({
    IKeychainService? keychainService,
    IFileEncryptionService? encryptionService,
  })  : _keychainService = keychainService ?? FlutterKeychainService(),
        _encryptionService = encryptionService ?? XorFileEncryptionService();

  // ============================================================
  // Directory Management (for attempt history)
  // ============================================================

  Future<void> _initializeDirectory() async {
    if (_secureDirectory != null && await _secureDirectory!.exists()) return;

    try {
      developer.log('Initializing secure storage directory', name: _logName);

      Directory appDir = Platform.isIOS || Platform.isMacOS
          ? await getApplicationSupportDirectory()
          : await getApplicationDocumentsDirectory();

      _secureDirectory = Directory('${appDir.path}/secure_auth');

      if (!await _secureDirectory!.exists()) {
        await _secureDirectory!.create(recursive: true);

        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['700', _secureDirectory!.path]);
        }
      }
    } catch (e, stackTrace) {
      developer.log('CRITICAL: Failed to init storage',
          name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to initialize secure storage: $e');
    }
  }

  Future<String> _getFilePath(String filename) async {
    await _initializeDirectory();
    return '${_secureDirectory!.path}/$filename';
  }

  // ============================================================
  // PIN Hash Operations (Keychain-backed)
  // ============================================================

  @override
  Future<PinHash?> loadPinHash() async {
    try {
      developer.log('Loading PIN hash from keychain...', name: _logName);

      // Check for migration from file-based storage
      await _migrateToKeychain();

      // Load from keychain
      final data = await _keychainService.readMap(_pinHashKey);

      if (data == null) {
        developer.log('PIN hash not found in keychain', name: _logName);
        return null;
      }

      PinHash pinHash = PinHash.fromMap(data);
      developer.log('PIN hash loaded from keychain successfully', name: _logName);
      return pinHash;
    } catch (e, stackTrace) {
      developer.log('ERROR loading PIN hash',
          name: _logName, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> savePinHash(PinHash pinHash) async {
    try {
      developer.log('Saving PIN hash to keychain...', name: _logName);

      Map<String, dynamic> data = pinHash.toMap();
      await _keychainService.writeMap(_pinHashKey, data);

      developer.log('PIN hash saved to keychain successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR saving PIN hash',
          name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to save PIN hash: $e');
    }
  }

  @override
  Future<void> deletePinHash() async {
    try {
      developer.log('Deleting PIN hash from keychain', name: _logName);
      await _keychainService.delete(_pinHashKey);
      developer.log('PIN hash deleted from keychain', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR deleting PIN hash',
          name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to delete PIN hash: $e');
    }
  }

  // ============================================================
  // Attempt History Operations (File-based with secure deletion)
  // ============================================================

  @override
  Future<AuthAttemptHistory> loadAttemptHistory() async {
    try {
      developer.log('Loading attempt history', name: _logName);

      String filePath = await _getFilePath(_attemptHistoryFile);
      File file = File(filePath);

      if (!await file.exists()) {
        developer.log('Attempt history not found, returning empty',
            name: _logName);
        return AuthAttemptHistory([]);
      }

      String encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return AuthAttemptHistory([]);
      }

      Map<String, dynamic> data = _encryptionService.decrypt(encryptedContent);
      AuthAttemptHistory history = AuthAttemptHistory.fromMap(data);

      developer.log('Loaded ${history.attempts.length} attempts',
          name: _logName);
      return history;
    } catch (e, stackTrace) {
      developer.log('ERROR loading attempt history',
          name: _logName, error: e, stackTrace: stackTrace);
      return AuthAttemptHistory([]);
    }
  }

  @override
  Future<void> saveAttemptHistory(AuthAttemptHistory history) async {
    try {
      developer.log('Saving ${history.attempts.length} attempts',
          name: _logName);

      String filePath = await _getFilePath(_attemptHistoryFile);
      Map<String, dynamic> data = history.toMap();
      String encryptedContent = _encryptionService.encrypt(data);

      File file = File(filePath);
      await file.writeAsString(encryptedContent, flush: true);

      developer.log('Attempt history saved', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR saving attempt history',
          name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to save attempt history: $e');
    }
  }

  // ============================================================
  // Utility Operations
  // ============================================================

  @override
  Future<void> clearAll() async {
    try {
      developer.log('Clearing all auth data', name: _logName);

      await deletePinHash();

      String attemptFilePath = await _getFilePath(_attemptHistoryFile);
      File attemptFile = File(attemptFilePath);
      if (await attemptFile.exists()) {
        await _secureDeleteFile(attemptFile);
      }

      developer.log('All auth data cleared', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR clearing auth data',
          name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to clear auth data: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _initializeDirectory();
      return await _secureDirectory!.exists();
    } catch (e) {
      developer.log('Storage not available', name: _logName, error: e);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      await _initializeDirectory();

      String attemptPath = await _getFilePath(_attemptHistoryFile);
      File attemptFile = File(attemptPath);

      final pinHashExists = await _keychainService.containsKey(_pinHashKey);

      return {
        'storageType': 'keychain',
        'directoryPath': _secureDirectory?.path,
        'directoryExists': await _secureDirectory?.exists() ?? false,
        'pinHashInKeychain': pinHashExists,
        'attemptHistoryFileExists': await attemptFile.exists(),
        'attemptHistoryFileSize':
            await attemptFile.exists() ? await attemptFile.length() : 0,
      };
    } catch (e) {
      developer.log('ERROR getting storage info', name: _logName, error: e);
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> runDiagnostics() async {
    developer.log('=== Running Storage Diagnostics ===', name: _logName);

    Map<String, dynamic> diagnostics = {};

    try {
      diagnostics['directoryInitialized'] = _secureDirectory != null;
      diagnostics['storageAvailable'] = await isAvailable();
      diagnostics['storageType'] = 'platform_keychain';
      diagnostics.addAll(await getStorageInfo());

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

      developer.log('Diagnostics complete', name: _logName);
    } catch (e, stackTrace) {
      developer.log('Diagnostics failed',
          name: _logName, error: e, stackTrace: stackTrace);
      diagnostics['diagnosticsError'] = e.toString();
    }

    return diagnostics;
  }

  // ============================================================
  // Private Helpers
  // ============================================================

  /// Secure file deletion with multi-pass overwrite
  Future<void> _secureDeleteFile(File file) async {
    try {
      int fileSize = await file.length();
      SecureRandom secureRandom = SecureRandom.instance;

      // Overwrite with random data 3 times
      for (int pass = 0; pass < 3; pass++) {
        Uint8List randomData = secureRandom.nextBytes(fileSize);
        await file.writeAsBytes(randomData, flush: true);
      }

      // Final overwrite with zeros
      await file.writeAsBytes(Uint8List(fileSize), flush: true);
      await file.delete();
    } catch (e) {
      try {
        await file.delete();
      } catch (deleteError) {
        throw Exception('Failed to delete file: $e, $deleteError');
      }
    }
  }

  /// Migrate PIN hash from legacy file-based storage to keychain
  Future<void> _migrateToKeychain() async {
    if (_migrationChecked) return;
    _migrationChecked = true;

    try {
      // Check if already in keychain
      if (await _keychainService.containsKey(_pinHashKey)) {
        developer.log('PIN hash already in keychain, skipping migration',
            name: _logName);
        return;
      }

      // Check for legacy file
      String filePath = await _getFilePath(_pinHashFile);
      File legacyFile = File(filePath);

      if (!await legacyFile.exists()) {
        developer.log('No legacy PIN file found', name: _logName);
        return;
      }

      developer.log('Migrating PIN hash from file to keychain...', name: _logName);

      // Read from legacy file
      String encryptedContent = await legacyFile.readAsString();
      if (encryptedContent.isEmpty) {
        await _secureDeleteFile(legacyFile);
        return;
      }

      // Decrypt and migrate to keychain
      Map<String, dynamic> data = _encryptionService.decrypt(encryptedContent);
      await _keychainService.writeMap(_pinHashKey, data);

      // Securely delete legacy file
      await _secureDeleteFile(legacyFile);

      developer.log('PIN hash migrated to keychain successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log('Migration error (non-fatal)',
          name: _logName, error: e, stackTrace: stackTrace);
    }
  }
}
