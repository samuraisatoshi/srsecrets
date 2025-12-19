/// Secure Storage Repository Implementation
///
/// Provides secure file-based storage for PIN authentication data.
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

/// File-based secure storage for authentication data
class SecureStorageRepository implements IPinStorageRepository {
  static const String _logName = 'SecureStorageRepository';
  static const String _pinHashFile = 'pin_hash.dat';
  static const String _attemptHistoryFile = 'auth_attempts.dat';

  final IFileEncryptionService _encryptionService;
  Directory? _secureDirectory;

  SecureStorageRepository({
    IFileEncryptionService? encryptionService,
  }) : _encryptionService = encryptionService ?? XorFileEncryptionService();

  // ============================================================
  // Directory Management
  // ============================================================

  Future<void> _initializeDirectory() async {
    if (_secureDirectory != null) return;

    try {
      developer.log('Initializing secure storage directory', name: _logName);

      Directory appDir = Platform.isIOS || Platform.isMacOS
          ? await getApplicationSupportDirectory()
          : await getApplicationDocumentsDirectory();

      _secureDirectory = Directory('${appDir.path}/secure_auth');

      developer.log('Secure directory: ${_secureDirectory!.path}', name: _logName);

      if (!await _secureDirectory!.exists()) {
        await _secureDirectory!.create(recursive: true);
        developer.log('Created secure directory', name: _logName);

        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['700', _secureDirectory!.path]);
        }
      }
    } catch (e, stackTrace) {
      developer.log('CRITICAL: Failed to init storage', name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to initialize secure storage: $e');
    }
  }

  Future<String> _getFilePath(String filename) async {
    await _initializeDirectory();
    return '${_secureDirectory!.path}/$filename';
  }

  // ============================================================
  // PIN Hash Operations
  // ============================================================

  @override
  Future<PinHash?> loadPinHash() async {
    try {
      developer.log('Loading PIN hash', name: _logName);

      await _migrateOldData();

      String filePath = await _getFilePath(_pinHashFile);
      File file = File(filePath);

      if (!await file.exists()) {
        developer.log('PIN hash file not found', name: _logName);
        return null;
      }

      String encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        developer.log('PIN hash file is empty', name: _logName);
        return null;
      }

      Map<String, dynamic> data = _encryptionService.decrypt(encryptedContent);
      PinHash pinHash = PinHash.fromMap(data);

      developer.log('PIN hash loaded successfully', name: _logName);
      return pinHash;
    } catch (e, stackTrace) {
      developer.log('ERROR loading PIN hash', name: _logName, error: e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> savePinHash(PinHash pinHash) async {
    try {
      developer.log('Saving PIN hash', name: _logName);

      String filePath = await _getFilePath(_pinHashFile);
      Map<String, dynamic> data = pinHash.toMap();
      String encryptedContent = _encryptionService.encrypt(data);

      File file = File(filePath);
      await file.writeAsString(encryptedContent, flush: true);

      developer.log('PIN hash saved successfully', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR saving PIN hash', name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to save PIN hash: $e');
    }
  }

  @override
  Future<void> deletePinHash() async {
    try {
      developer.log('Deleting PIN hash', name: _logName);

      String filePath = await _getFilePath(_pinHashFile);
      File file = File(filePath);

      if (await file.exists()) {
        await _secureDeleteFile(file);
        developer.log('PIN hash deleted', name: _logName);
      }
    } catch (e, stackTrace) {
      developer.log('ERROR deleting PIN hash', name: _logName, error: e, stackTrace: stackTrace);
      throw Exception('Failed to delete PIN hash: $e');
    }
  }

  // ============================================================
  // Attempt History Operations
  // ============================================================

  @override
  Future<AuthAttemptHistory> loadAttemptHistory() async {
    try {
      developer.log('Loading attempt history', name: _logName);

      String filePath = await _getFilePath(_attemptHistoryFile);
      File file = File(filePath);

      if (!await file.exists()) {
        developer.log('Attempt history not found, returning empty', name: _logName);
        return AuthAttemptHistory([]);
      }

      String encryptedContent = await file.readAsString();
      if (encryptedContent.isEmpty) {
        return AuthAttemptHistory([]);
      }

      Map<String, dynamic> data = _encryptionService.decrypt(encryptedContent);
      AuthAttemptHistory history = AuthAttemptHistory.fromMap(data);

      developer.log('Loaded ${history.attempts.length} attempts', name: _logName);
      return history;
    } catch (e, stackTrace) {
      developer.log('ERROR loading attempt history', name: _logName, error: e, stackTrace: stackTrace);
      return AuthAttemptHistory([]);
    }
  }

  @override
  Future<void> saveAttemptHistory(AuthAttemptHistory history) async {
    try {
      developer.log('Saving ${history.attempts.length} attempts', name: _logName);

      String filePath = await _getFilePath(_attemptHistoryFile);
      Map<String, dynamic> data = history.toMap();
      String encryptedContent = _encryptionService.encrypt(data);

      File file = File(filePath);
      await file.writeAsString(encryptedContent, flush: true);

      developer.log('Attempt history saved', name: _logName);
    } catch (e, stackTrace) {
      developer.log('ERROR saving attempt history', name: _logName, error: e, stackTrace: stackTrace);
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
      developer.log('ERROR clearing auth data', name: _logName, error: e, stackTrace: stackTrace);
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

      String pinPath = await _getFilePath(_pinHashFile);
      String attemptPath = await _getFilePath(_attemptHistoryFile);

      File pinFile = File(pinPath);
      File attemptFile = File(attemptPath);

      return {
        'directoryPath': _secureDirectory?.path,
        'directoryExists': await _secureDirectory?.exists() ?? false,
        'pinHashFileExists': await pinFile.exists(),
        'pinHashFileSize': await pinFile.exists() ? await pinFile.length() : 0,
        'attemptHistoryFileExists': await attemptFile.exists(),
        'attemptHistoryFileSize': await attemptFile.exists() ? await attemptFile.length() : 0,
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
      developer.log('Diagnostics failed', name: _logName, error: e, stackTrace: stackTrace);
      diagnostics['diagnosticsError'] = e.toString();
    }

    return diagnostics;
  }

  // ============================================================
  // Private Helpers
  // ============================================================

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

  Future<void> _migrateOldData() async {
    try {
      Directory oldDocDir = await getApplicationDocumentsDirectory();
      Directory oldSecureDir = Directory('${oldDocDir.path}/secure_auth');

      if (!await oldSecureDir.exists()) return;

      developer.log('Found old storage, checking migration', name: _logName);

      File oldPinFile = File('${oldSecureDir.path}/$_pinHashFile');
      String newPinPath = await _getFilePath(_pinHashFile);
      File newPinFile = File(newPinPath);

      if (await oldPinFile.exists() && !await newPinFile.exists()) {
        developer.log('Migrating PIN data', name: _logName);
        await oldPinFile.copy(newPinPath);

        File oldAttemptFile = File('${oldSecureDir.path}/$_attemptHistoryFile');
        if (await oldAttemptFile.exists()) {
          String newAttemptPath = await _getFilePath(_attemptHistoryFile);
          await oldAttemptFile.copy(newAttemptPath);
        }

        developer.log('Migration complete', name: _logName);
      }

      await _cleanupOldDirectory(oldSecureDir);
    } catch (e, stackTrace) {
      developer.log('Migration error (non-fatal)', name: _logName, error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _cleanupOldDirectory(Directory oldDir) async {
    try {
      if (!await oldDir.exists()) return;

      developer.log('Cleaning old directory', name: _logName);

      await for (var entity in oldDir.list()) {
        if (entity is File) {
          await _secureDeleteFile(entity);
        }
      }
      await oldDir.delete(recursive: true);

      developer.log('Old directory cleaned', name: _logName);
    } catch (e, stackTrace) {
      developer.log('Cleanup error', name: _logName, error: e, stackTrace: stackTrace);
    }
  }
}
