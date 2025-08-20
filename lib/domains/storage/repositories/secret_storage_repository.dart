import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Repository for persisting secret metadata
/// Note: This only stores metadata, not the actual secret content
class SecretStorageRepository {
  static const String _secretsFile = 'secrets_metadata.json';
  Directory? _storageDirectory;

  /// Initialize storage directory
  Future<void> _initializeDirectory() async {
    if (_storageDirectory != null) return;

    try {
      Directory appDir;
      if (Platform.isIOS || Platform.isMacOS) {
        appDir = await getApplicationSupportDirectory();
      } else {
        appDir = await getApplicationDocumentsDirectory();
      }

      _storageDirectory = Directory('${appDir.path}/secrets');

      if (!await _storageDirectory!.exists()) {
        await _storageDirectory!.create(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to initialize storage directory: $e');
    }
  }

  /// Get the file path for secrets storage
  Future<String> _getSecretsFilePath() async {
    await _initializeDirectory();
    return '${_storageDirectory!.path}/$_secretsFile';
  }

  /// Save secrets metadata to storage
  Future<void> saveSecrets(List<Map<String, dynamic>> secrets) async {
    try {
      String filePath = await _getSecretsFilePath();
      File file = File(filePath);

      // Convert to JSON and save
      String jsonContent = jsonEncode(secrets);
      await file.writeAsString(jsonContent);
    } catch (e) {
      throw Exception('Failed to save secrets: $e');
    }
  }

  /// Load secrets metadata from storage
  Future<List<Map<String, dynamic>>> loadSecrets() async {
    try {
      String filePath = await _getSecretsFilePath();
      File file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      String content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      List<dynamic> jsonList = jsonDecode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // Return empty list if loading fails
      return [];
    }
  }

  /// Clear all saved secrets
  Future<void> clearSecrets() async {
    try {
      String filePath = await _getSecretsFilePath();
      File file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear secrets: $e');
    }
  }
}