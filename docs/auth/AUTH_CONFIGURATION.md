# Authentication Configuration Guide

## Overview

This guide provides comprehensive configuration options for the SRSecrets authentication system, including PIN requirements, security parameters, platform-specific settings, and migration procedures. All configurations prioritize security while maintaining usability within the air-gapped design constraints.

## PIN Requirements Configuration

### PinRequirements Class

The `PinRequirements` class defines validation rules and security policies for PIN creation and management.

```dart
class PinRequirements {
  final int minLength;
  final int maxLength;
  final bool requireDigitsOnly;
  final bool preventCommonPatterns;
  final bool preventRepeatingDigits;
  final bool preventSequentialDigits;
  final List<String> customBlockedPins;
}
```

### Predefined Security Levels

#### Basic Level
```dart
static const PinRequirements basic = PinRequirements(
  minLength: 4,
  maxLength: 12,
  requireDigitsOnly: true,
  preventCommonPatterns: false,
  preventRepeatingDigits: false,
  preventSequentialDigits: false,
  customBlockedPins: [],
);
```

**Use Cases**:
- Development and testing environments
- Users requiring maximum convenience
- Legacy compatibility requirements

**Security Trade-offs**:
- Vulnerable to common PIN attacks
- Allows weak patterns (1234, 0000, etc.)
- Minimal computational overhead

#### Standard Level (Default)
```dart
static const PinRequirements standard = PinRequirements(
  minLength: 4,
  maxLength: 8,
  requireDigitsOnly: true,
  preventCommonPatterns: true,
  preventRepeatingDigits: true,
  preventSequentialDigits: false,
  customBlockedPins: [],
);
```

**Use Cases**:
- General consumer applications
- Balanced security and usability
- Most mobile applications

**Security Features**:
- Blocks most common weak PINs
- Prevents obvious patterns
- Good usability with reasonable security

#### Secure Level (Recommended)
```dart
static const PinRequirements secure = PinRequirements(
  minLength: 6,
  maxLength: 12,
  requireDigitsOnly: true,
  preventCommonPatterns: true,
  preventRepeatingDigits: true,
  preventSequentialDigits: true,
  customBlockedPins: [],
);
```

**Use Cases**:
- High-security applications
- Cryptographic secret management
- Enterprise deployments
- Sensitive data protection

**Security Features**:
- Longer minimum PIN length
- Comprehensive pattern detection
- Maximum protection against dictionary attacks
- Future-proofed security parameters

### Custom PIN Requirements

#### Creating Custom Requirements
```dart
PinRequirements customRequirements = PinRequirements(
  minLength: 8,
  maxLength: 16,
  requireDigitsOnly: false,  // Allow alphanumeric
  preventCommonPatterns: true,
  preventRepeatingDigits: true,
  preventSequentialDigits: true,
  customBlockedPins: [
    'password',
    'admin123',
    'company2024',
    // Organization-specific blocked patterns
  ],
);
```

#### Advanced Pattern Customization
```dart
class EnhancedPinRequirements extends PinRequirements {
  final RegExp? customPatternFilter;
  final bool requireMixedCase;
  final bool requireSpecialChars;
  final int minimumUniqueChars;
  
  const EnhancedPinRequirements({
    // Standard requirements
    required super.minLength,
    required super.maxLength,
    
    // Enhanced requirements
    this.customPatternFilter,
    this.requireMixedCase = false,
    this.requireSpecialChars = false,
    this.minimumUniqueChars = 3,
  });
}
```

### PIN Length Considerations

#### Length Security Analysis
```
4-digit PIN:  10,000 combinations (10^4)
5-digit PIN:  100,000 combinations (10^5)  
6-digit PIN:  1,000,000 combinations (10^6)
8-digit PIN:  100,000,000 combinations (10^8)
```

#### Recommended Length by Use Case
- **Basic Security**: 4-6 digits
- **Standard Security**: 6-8 digits
- **High Security**: 8+ digits
- **Maximum Security**: 12+ digits with mixed characters

#### Usability Impact Assessment
```
Length | Memorability | Input Speed | Security Level
-------|-------------|-------------|---------------
4      | Excellent   | Very Fast   | Basic
6      | Good        | Fast        | Standard  
8      | Moderate    | Moderate    | High
10+    | Difficult   | Slow        | Maximum
```

## Cryptographic Parameters

### PBKDF2 Configuration

#### Current Default Parameters
```dart
class Pbkdf2Config {
  static const int defaultIterations = 200000;
  static const int minIterations = 100000;
  static const int saltLength = 32;  // 256 bits
  static const int hashLength = 32;  // 256 bits
}
```

#### Iteration Count Calibration
```dart
// Device-specific calibration
Future<int> calibrateIterations() async {
  const int targetMilliseconds = 500;
  const int testIterations = 10000;
  
  Stopwatch stopwatch = Stopwatch()..start();
  await performTestHashing(testIterations);
  stopwatch.stop();
  
  double msPerIteration = stopwatch.elapsedMilliseconds / testIterations;
  int recommendedIterations = (targetMilliseconds / msPerIteration).round();
  
  return math.max(recommendedIterations, minIterations);
}
```

#### Performance Targets by Device Class
```
Device Class     | Target Time | Recommended Iterations
----------------|-------------|----------------------
Low-end Mobile  | 800ms       | 150,000 - 200,000
Mid-range Mobile| 500ms       | 200,000 - 300,000
High-end Mobile | 300ms       | 300,000 - 500,000
Desktop/Server  | 200ms       | 500,000 - 1,000,000
```

### Security Parameter Evolution

#### Upgrade Detection Logic
```dart
class SecurityParameterValidator {
  static const int currentMinIterations = 200000;
  static const int currentSaltLength = 32;
  
  static bool needsUpgrade(PinHash hash) {
    return hash.iterations < currentMinIterations ||
           hash.salt.length < currentSaltLength ||
           hash.version < currentSchemaVersion;
  }
}
```

#### Automatic Upgrade Process
```dart
// Triggered during successful authentication
if (hash.needsUpgrade()) {
  showUpgradePrompt(
    title: 'Security Upgrade Available',
    message: 'Enhanced security parameters are available. Upgrade now?',
    onAccept: () async {
      try {
        await pinService.upgradeHash(currentPin);
        showSuccess('Security upgraded successfully');
      } catch (e) {
        showError('Upgrade failed: $e');
      }
    },
    onDefer: () => scheduleUpgradeReminder(),
  );
}
```

## Lockout Configuration

### Progressive Lockout Schedule

#### Default Configuration
```dart
class LockoutConfig {
  static const Map<int, Duration> lockoutSchedule = {
    5:  Duration(seconds: 30),      // First lockout
    10: Duration(minutes: 5),       // Second tier
    15: Duration(minutes: 30),      // Third tier
    20: Duration(hours: 2),         // Fourth tier
    25: Duration(hours: 8),         // Fifth tier
    30: Duration(hours: 24),        // Maximum lockout
  };
  
  static const int maxLockoutHours = 24;
  static const int attemptHistoryRetention = 100;
}
```

#### Custom Lockout Policies
```dart
// Conservative policy (faster lockout)
class ConservativeLockoutConfig extends LockoutConfig {
  static const Map<int, Duration> lockoutSchedule = {
    3:  Duration(minutes: 1),
    5:  Duration(minutes: 5),
    8:  Duration(minutes: 30),
    12: Duration(hours: 2),
    15: Duration(hours: 8),
    20: Duration(hours: 24),
  };
}

// Permissive policy (slower lockout)
class PermissiveLockoutConfig extends LockoutConfig {
  static const Map<int, Duration> lockoutSchedule = {
    10: Duration(seconds: 30),
    20: Duration(minutes: 5),
    30: Duration(minutes: 30),
    40: Duration(hours: 2),
    50: Duration(hours: 12),
  };
}
```

#### Enterprise Lockout Configuration
```dart
class EnterpriseLockoutConfig {
  final bool enableAccountDisabling;
  final Duration maxLockoutDuration;
  final int maxDailyAttempts;
  final bool requireAdminUnlock;
  final List<String> notificationEndpoints;
  
  const EnterpriseLockoutConfig({
    this.enableAccountDisabling = true,
    this.maxLockoutDuration = Duration(hours: 72),
    this.maxDailyAttempts = 50,
    this.requireAdminUnlock = false,
    this.notificationEndpoints = const [],
  });
}
```

### Lockout Recovery Options

#### User Self-Recovery
```dart
// Standard recovery after lockout expiration
Future<bool> canAttemptAuthentication() async {
  Duration? remaining = await pinService.getLockoutRemaining();
  return remaining == null;
}

// Manual attempt history clearing (development only)
Future<void> clearLockoutState() async {
  if (kDebugMode) {
    await pinService.clearAttemptHistory();
  }
}
```

#### Administrative Recovery
```dart
class AdminRecoveryService {
  Future<void> unlockAccount(String adminCredentials) async {
    if (await validateAdminCredentials(adminCredentials)) {
      await pinService.clearAttemptHistory();
      await logSecurityEvent('Admin unlock performed');
    }
  }
  
  Future<void> resetUserPin(String newPin) async {
    await pinService.resetPin(newPin);
    await logSecurityEvent('Admin PIN reset performed');
  }
}
```

## Platform-Specific Configuration

### iOS/macOS Configuration

#### Keychain Integration (Optional Enhancement)
```dart
class KeychainConfig {
  static const bool useKeychain = false;  // Currently disabled
  static const String keychainService = 'com.srsecrets.auth';
  static const String keychainAccessGroup = '';
  static const bool requireBiometrics = false;
}

// Future enhancement for hardware security
class iOSSecurityConfig extends PlatformConfig {
  final bool useSecureEnclave;
  final bool requireTouchID;
  final bool requireFaceID;
  final bool allowFallbackToPIN;
  
  const iOSSecurityConfig({
    this.useSecureEnclave = false,
    this.requireTouchID = false,
    this.requireFaceID = false,
    this.allowFallbackToPIN = true,
  });
}
```

#### App Transport Security
```xml
<!-- Info.plist configuration for air-gapped operation -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsLocalNetworking</key>
    <false/>
</dict>
```

### Android Configuration

#### Manifest Security Settings
```xml
<!-- AndroidManifest.xml security configuration -->
<application
    android:allowBackup="false"
    android:fullBackupContent="false"
    android:dataExtractionRules="@xml/data_extraction_rules">
    
    <!-- Prevent debugging in production -->
    <meta-data android:name="android.app.extra.DEBUGGING_ENABLED" 
               android:value="false" />
</application>

<!-- Network security config for air-gapped operation -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <!-- No domains allowed -->
    </domain-config>
</network-security-config>
```

#### ProGuard Configuration
```proguard
# Protect authentication classes
-keep class **auth** { *; }
-keep class **crypto** { *; }

# Obfuscate but preserve functionality
-keepclassmembers class * {
    native <methods>;
}

# Remove debugging information
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
```

### Desktop Platform Configuration

#### Linux Security Settings
```bash
# Set restrictive umask for the application
umask 077

# Create secure storage directory
mkdir -p ~/.local/share/srsecrets/secure_auth
chmod 700 ~/.local/share/srsecrets/secure_auth
```

#### Windows Configuration
```cpp
// Platform-specific security settings
class WindowsSecurityConfig {
  // File encryption using Windows APIs
  static const bool useWindowsEncryption = true;
  
  // ACL configuration
  static const bool restrictToCurrentUser = true;
  static const bool removeInheritance = true;
}
```

#### macOS Sandboxing
```xml
<!-- macOS sandbox entitlements -->
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<false/>
<key>com.apple.security.network.client</key>
<false/>
<key>com.apple.security.network.server</key>
<false/>
```

## Environment-Specific Configuration

### Development Configuration

#### Debug Settings
```dart
class DebugAuthConfig {
  static const bool enableDebugLogging = true;
  static const bool allowWeakPins = true;
  static const bool skipLockouts = false;
  static const int reducedIterations = 1000;  // Faster for testing
  
  static PinRequirements get debugRequirements => PinRequirements(
    minLength: 1,  // Allow very short PINs for testing
    maxLength: 20,
    requireDigitsOnly: false,
    preventCommonPatterns: false,
    preventRepeatingDigits: false,
    preventSequentialDigits: false,
    customBlockedPins: [],
  );
}
```

#### Test Configuration
```dart
class TestAuthConfig {
  static const String testPinHash = 'test_hash_12345';
  static const bool mockCryptoOperations = true;
  static const bool deterministicSalt = true;
  
  // Predictable test data
  static Uint8List get testSalt => Uint8List.fromList([
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    // ... repeated pattern for testing
  ]);
}
```

### Production Configuration

#### Security Hardening
```dart
class ProductionAuthConfig {
  static const bool enableDebugLogging = false;
  static const bool allowWeakPins = false;
  static const bool enforceStrictValidation = true;
  static const int productionIterations = 200000;
  
  // Production PIN requirements
  static const PinRequirements productionRequirements = PinRequirements.secure;
  
  // Enhanced lockout for production
  static const Map<int, Duration> productionLockout = {
    3:  Duration(minutes: 1),
    6:  Duration(minutes: 10),
    10: Duration(hours: 1),
    15: Duration(hours: 6),
    20: Duration(hours: 24),
  };
}
```

#### Performance Optimization
```dart
class PerformanceConfig {
  static const bool enableIterationCaching = true;
  static const Duration calibrationInterval = Duration(days: 7);
  static const int maxConcurrentOperations = 1;
  static const bool enableMemoryOptimization = true;
}
```

### Enterprise Configuration

#### Compliance Settings
```dart
class ComplianceConfig {
  static const bool requireFIPS140_2 = false;  // Not yet implemented
  static const bool enableAuditLogging = true;
  static const Duration auditLogRetention = Duration(days: 90);
  static const bool requireDualApproval = false;
  
  // Regulatory compliance flags
  static const bool gdprCompliant = true;
  static const bool hipaaCompliant = false;
  static const bool sox404Compliant = false;
}
```

#### Integration Settings
```dart
class EnterpriseIntegrationConfig {
  static const bool enableActiveDirectory = false;
  static const bool enableLDAP = false;
  static const bool enableSAML = false;  // Future consideration
  static const bool enableSyslog = false;
  
  // Monitoring integration
  static const List<String> metricsEndpoints = [];
  static const bool enableSNMP = false;
}
```

## Migration and Upgrade Procedures

### Configuration Migration

#### Version Detection
```dart
class ConfigVersionManager {
  static const String currentVersion = '1.2.0';
  
  static bool needsMigration(String storedVersion) {
    return Version.parse(storedVersion) < Version.parse(currentVersion);
  }
  
  static Future<void> migrateConfiguration(
    String fromVersion, 
    String toVersion
  ) async {
    if (fromVersion == '1.0.0' && toVersion == '1.2.0') {
      await _migrateFromV1_0ToV1_2();
    }
  }
}
```

#### Migration Procedures
```dart
Future<void> _migrateFromV1_0ToV1_2() async {
  // 1. Update security parameters
  if (currentIterations < 200000) {
    scheduleSecurityUpgrade();
  }
  
  // 2. Migrate storage location
  await migrateStorageLocation();
  
  // 3. Update PIN requirements
  await updatePinRequirements(PinRequirements.secure);
  
  // 4. Clean up legacy data
  await cleanupLegacyConfiguration();
}
```

### Security Parameter Updates

#### Automated Update Process
```dart
class SecurityUpdateManager {
  Future<void> checkForSecurityUpdates() async {
    SecurityParameters latest = await getLatestSecurityParameters();
    SecurityParameters current = await getCurrentSecurityParameters();
    
    if (latest.isNewerThan(current)) {
      await promptForSecurityUpdate(latest);
    }
  }
  
  Future<void> applySecurityUpdate(SecurityParameters params) async {
    // 1. Validate new parameters
    validateSecurityParameters(params);
    
    // 2. Update configuration
    await updateSecurityConfiguration(params);
    
    // 3. Schedule hash upgrades for existing users
    await scheduleHashUpgrades();
    
    // 4. Log security update
    await logSecurityEvent('Security parameters updated', params);
  }
}
```

### Rollback Procedures

#### Configuration Rollback
```dart
class ConfigRollbackManager {
  Future<void> rollbackToVersion(String targetVersion) async {
    try {
      // 1. Validate rollback target
      await validateRollbackTarget(targetVersion);
      
      // 2. Backup current configuration
      await backupCurrentConfiguration();
      
      // 3. Apply rollback configuration
      await applyRollbackConfiguration(targetVersion);
      
      // 4. Verify rollback success
      await verifyRollbackSuccess();
      
    } catch (e) {
      // Restore from backup if rollback fails
      await restoreFromBackup();
      rethrow;
    }
  }
}
```

## Configuration Validation

### Validation Rules

#### PIN Requirements Validation
```dart
class PinRequirementsValidator {
  static ValidationResult validate(PinRequirements requirements) {
    List<String> errors = [];
    
    // Length validation
    if (requirements.minLength < 1) {
      errors.add('Minimum length must be at least 1');
    }
    if (requirements.maxLength < requirements.minLength) {
      errors.add('Maximum length must be >= minimum length');
    }
    if (requirements.maxLength > 50) {
      errors.add('Maximum length should not exceed 50');
    }
    
    // Security validation
    if (requirements.minLength < 4 && requirements.preventCommonPatterns) {
      errors.add('Common pattern prevention requires min length >= 4');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

#### Security Parameters Validation
```dart
class SecurityParametersValidator {
  static ValidationResult validate(SecurityParameters params) {
    List<String> errors = [];
    
    // PBKDF2 validation
    if (params.iterations < 100000) {
      errors.add('Iteration count must be at least 100,000');
    }
    if (params.iterations > 10000000) {
      errors.add('Iteration count should not exceed 10,000,000');
    }
    
    // Salt validation
    if (params.saltLength < 16) {
      errors.add('Salt length must be at least 16 bytes');
    }
    if (params.saltLength > 64) {
      errors.add('Salt length should not exceed 64 bytes');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
```

### Configuration Testing

#### Automated Configuration Tests
```dart
@TestOn('vm')
void main() {
  group('Configuration Validation', () {
    test('Default PIN requirements are valid', () {
      expect(
        PinRequirementsValidator.validate(PinRequirements.secure),
        isTrue,
      );
    });
    
    test('Security parameters meet minimum standards', () {
      expect(
        SecurityParametersValidator.validate(SecurityParameters.default),
        isTrue,
      );
    });
    
    test('Lockout configuration is reasonable', () {
      expect(
        LockoutConfigValidator.validate(LockoutConfig.default),
        isTrue,
      );
    });
  });
}
```

## Best Practices and Recommendations

### Configuration Management

#### Version Control
- **Track Changes**: Use version control for all configuration changes
- **Review Process**: Require security review for configuration modifications
- **Testing**: Test all configuration changes in development environment
- **Documentation**: Document the rationale for all configuration decisions

#### Security-First Approach
- **Conservative Defaults**: Choose secure defaults over convenient ones
- **Gradual Relaxation**: Start strict and relax only when necessary
- **Regular Review**: Periodically review and update security parameters
- **Compliance Alignment**: Ensure configurations meet regulatory requirements

#### Performance Considerations
- **Device Calibration**: Calibrate PBKDF2 iterations for target devices
- **User Experience**: Balance security with acceptable user experience
- **Resource Monitoring**: Monitor resource usage with different configurations
- **Scalability Planning**: Consider impact of configuration on system scalability

### Deployment Guidelines

#### Staged Rollout
1. **Development Testing**: Thoroughly test in development environment
2. **Limited Beta**: Deploy to small group of beta users
3. **Performance Monitoring**: Monitor performance metrics closely
4. **Gradual Expansion**: Gradually expand to larger user base
5. **Full Deployment**: Complete rollout with monitoring

#### Rollback Preparation
- **Backup Strategy**: Maintain configuration backups before changes
- **Rollback Testing**: Test rollback procedures in development
- **Monitoring Alerts**: Set up alerts for configuration-related issues
- **Communication Plan**: Prepare user communication for configuration changes

---

*This configuration guide provides comprehensive options for customizing the SRSecrets authentication system. Always prioritize security considerations when making configuration changes, and thoroughly test all modifications before production deployment.*