/// Settings Repository Interface
///
/// Defines the contract for settings persistence following DDD principles.
/// Implementation-agnostic interface for settings storage operations.
library;

import '../models/app_settings.dart';

/// Abstract interface for settings persistence
abstract class ISettingsRepository {
  /// Load application settings from storage
  /// Returns null if no settings have been saved
  Future<AppSettings?> loadSettings();

  /// Save application settings to storage
  Future<void> saveSettings(AppSettings settings);

  /// Clear all stored settings (reset to defaults)
  Future<void> clearSettings();

  /// Check if storage is available and accessible
  Future<bool> isAvailable();
}

/// Exception thrown when settings repository operations fail
class SettingsRepositoryException implements Exception {
  const SettingsRepositoryException(this.message);
  final String message;

  @override
  String toString() => 'SettingsRepositoryException: $message';
}
