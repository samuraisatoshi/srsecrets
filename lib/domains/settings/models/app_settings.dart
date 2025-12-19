/// Application Settings Model
///
/// Defines user-configurable application settings following DDD principles.
/// Immutable value object for settings state.
library;

/// Immutable application settings model
class AppSettings {
  /// Whether PIN authentication is required on app launch
  /// Default: false (user can enable if desired)
  final bool pinRequired;

  /// Whether biometric authentication is enabled (future feature)
  final bool biometricEnabled;

  /// App theme mode preference
  final AppThemeMode themeMode;

  /// Whether user has seen PIN setup screen and made a decision
  /// When false, PIN setup screen is shown after onboarding
  final bool hasSeenPinSetup;

  const AppSettings({
    this.pinRequired = false,
    this.biometricEnabled = false,
    this.themeMode = AppThemeMode.system,
    this.hasSeenPinSetup = false,
  });

  /// Create default settings (PIN not required since no sensitive data stored)
  factory AppSettings.defaults() {
    return const AppSettings(
      pinRequired: false,
      biometricEnabled: false,
      themeMode: AppThemeMode.system,
      hasSeenPinSetup: false,
    );
  }

  /// Create settings from JSON map
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      pinRequired: json['pinRequired'] as bool? ?? false,
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      themeMode: AppThemeMode.fromString(json['themeMode'] as String?),
      hasSeenPinSetup: json['hasSeenPinSetup'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'pinRequired': pinRequired,
      'biometricEnabled': biometricEnabled,
      'themeMode': themeMode.name,
      'hasSeenPinSetup': hasSeenPinSetup,
    };
  }

  /// Create copy with modified values
  AppSettings copyWith({
    bool? pinRequired,
    bool? biometricEnabled,
    AppThemeMode? themeMode,
    bool? hasSeenPinSetup,
  }) {
    return AppSettings(
      pinRequired: pinRequired ?? this.pinRequired,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themeMode: themeMode ?? this.themeMode,
      hasSeenPinSetup: hasSeenPinSetup ?? this.hasSeenPinSetup,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.pinRequired == pinRequired &&
        other.biometricEnabled == biometricEnabled &&
        other.themeMode == themeMode &&
        other.hasSeenPinSetup == hasSeenPinSetup;
  }

  @override
  int get hashCode => Object.hash(pinRequired, biometricEnabled, themeMode, hasSeenPinSetup);

  @override
  String toString() {
    return 'AppSettings(pinRequired: $pinRequired, biometricEnabled: $biometricEnabled, themeMode: $themeMode, hasSeenPinSetup: $hasSeenPinSetup)';
  }
}

/// Theme mode preference
enum AppThemeMode {
  light,
  dark,
  system;

  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}
