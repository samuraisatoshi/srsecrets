/// SharedPreferences Settings Repository Implementation
///
/// Concrete implementation of ISettingsRepository using SharedPreferences.
/// Provides local storage for application settings.
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

/// SharedPreferences-based implementation of settings repository
class SharedPrefsSettingsRepository implements ISettingsRepository {
  static const String _settingsKey = 'app_settings';

  @override
  Future<AppSettings?> loadSettings() async {
    developer.log('[SettingsRepository] Loading settings...', name: 'settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson == null) {
        developer.log('[SettingsRepository] No settings found, returning null',
            name: 'settings');
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(settingsJson);
      final settings = AppSettings.fromJson(json);
      developer.log(
          '[SettingsRepository] Settings loaded: pinRequired=${settings.pinRequired}',
          name: 'settings');
      return settings;
    } catch (e, stackTrace) {
      developer.log('[SettingsRepository] ERROR loading settings: $e',
          name: 'settings', error: e, stackTrace: stackTrace);
      throw SettingsRepositoryException('Failed to load settings: $e');
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    developer.log(
        '[SettingsRepository] Saving settings: pinRequired=${settings.pinRequired}',
        name: 'settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
      developer.log('[SettingsRepository] Settings saved successfully',
          name: 'settings');
    } catch (e, stackTrace) {
      developer.log('[SettingsRepository] ERROR saving settings: $e',
          name: 'settings', error: e, stackTrace: stackTrace);
      throw SettingsRepositoryException('Failed to save settings: $e');
    }
  }

  @override
  Future<void> clearSettings() async {
    developer.log('[SettingsRepository] Clearing settings...', name: 'settings');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      developer.log('[SettingsRepository] Settings cleared', name: 'settings');
    } catch (e, stackTrace) {
      developer.log('[SettingsRepository] ERROR clearing settings: $e',
          name: 'settings', error: e, stackTrace: stackTrace);
      throw SettingsRepositoryException('Failed to clear settings: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Test write/read capability
      await prefs.setString('_test_key', 'test');
      await prefs.remove('_test_key');
      return true;
    } catch (e) {
      developer.log('[SettingsRepository] Storage not available: $e',
          name: 'settings');
      return false;
    }
  }
}
