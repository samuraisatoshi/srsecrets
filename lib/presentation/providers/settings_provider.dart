/// Settings Provider
///
/// State management for application settings following Provider pattern.
/// Manages loading, saving, and notifying listeners of settings changes.
library;

import 'package:flutter/foundation.dart';
import '../../domains/settings/models/app_settings.dart';
import '../../domains/settings/repositories/settings_repository.dart';
import '../../infrastructure/persistence/shared_prefs_settings_repository.dart';

/// Provider for application settings state management
class SettingsProvider extends ChangeNotifier {
  final ISettingsRepository _repository;

  bool _isLoading = false;
  bool _isInitialized = false;
  AppSettings _settings = AppSettings.defaults();
  String? _errorMessage;

  SettingsProvider({ISettingsRepository? repository})
      : _repository = repository ?? SharedPrefsSettingsRepository();

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  AppSettings get settings => _settings;
  String? get errorMessage => _errorMessage;

  /// Convenience getter for PIN requirement
  bool get isPinRequired => _settings.pinRequired;

  /// Convenience getter for biometric enabled
  bool get isBiometricEnabled => _settings.biometricEnabled;

  /// Convenience getter for whether user has seen PIN setup
  bool get hasSeenPinSetup => _settings.hasSeenPinSetup;

  /// Initialize provider by loading settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      final storedSettings = await _repository.loadSettings();
      if (storedSettings != null) {
        _settings = storedSettings;
      } else {
        // First launch: use defaults and save them
        _settings = AppSettings.defaults();
        await _repository.saveSettings(_settings);
      }
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to load settings: $e');
      // Use defaults on error
      _settings = AppSettings.defaults();
      _isInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Update PIN requirement setting
  /// Also marks hasSeenPinSetup as true
  Future<bool> setPinRequired(bool required) async {
    _clearError();
    try {
      final newSettings = _settings.copyWith(
        pinRequired: required,
        hasSeenPinSetup: true,
      );
      await _repository.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update PIN setting: $e');
      return false;
    }
  }

  /// Mark that user has completed PIN setup decision (set or skipped)
  Future<bool> markPinSetupSeen() async {
    _clearError();
    try {
      final newSettings = _settings.copyWith(hasSeenPinSetup: true);
      await _repository.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update PIN setup status: $e');
      return false;
    }
  }

  /// Update biometric setting
  Future<bool> setBiometricEnabled(bool enabled) async {
    _clearError();
    try {
      final newSettings = _settings.copyWith(biometricEnabled: enabled);
      await _repository.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update biometric setting: $e');
      return false;
    }
  }

  /// Update theme mode
  Future<bool> setThemeMode(AppThemeMode mode) async {
    _clearError();
    try {
      final newSettings = _settings.copyWith(themeMode: mode);
      await _repository.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update theme setting: $e');
      return false;
    }
  }

  /// Reset all settings to defaults
  Future<bool> resetToDefaults() async {
    _clearError();
    try {
      _settings = AppSettings.defaults();
      await _repository.saveSettings(_settings);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reset settings: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
