# Security Architecture

## Overview

SRSecrets implements a comprehensive security architecture designed for air-gapped operation with multiple layers of protection for cryptographic secret management. This document details the security design, threat model, and implementation of security controls across all application layers.

## Security Design Principles

### Core Security Principles

1. **Air-Gapped by Design**
   - Zero network connectivity during operation
   - No external API calls or data transmission
   - Complete local data processing and storage
   - Elimination of remote attack vectors

2. **Defense in Depth**
   - Multiple security layers prevent single points of failure
   - Cryptographic protection at data layer
   - Authentication protection at access layer
   - UI protection at presentation layer

3. **Zero Trust Architecture**
   - All data is encrypted at rest
   - All operations require authentication
   - All inputs are validated and sanitized
   - No implicit trust relationships

4. **Cryptographic Agility**
   - Configurable algorithm parameters
   - Interface-based crypto providers
   - Upgradeable security parameters
   - Future-proof design patterns

## Threat Model

### Assets Under Protection

**Primary Assets**:
- User secrets (passwords, private keys, sensitive data)
- Shamir shares containing fragments of secrets
- Derived cryptographic keys and hashes
- User authentication credentials (PIN hashes)

**Secondary Assets**:
- Application configuration data
- User preferences and settings
- Authentication attempt history
- Metadata about stored secrets

### Threat Actors

1. **Malicious Local Users**
   - Direct device access
   - File system access
   - Memory dump capabilities
   - Process inspection tools

2. **Malware on Device**
   - Memory scanning malware
   - Keylogging software
   - File system monitoring
   - Process injection attacks

3. **Physical Device Compromise**
   - Stolen or lost devices
   - Forensic analysis attempts
   - Cold boot attacks
   - Hardware-level attacks

4. **Side-Channel Attackers**
   - Timing analysis
   - Power consumption analysis
   - Cache timing attacks
   - Acoustic cryptanalysis

### Attack Vectors

**Confidentiality Attacks**:
- Memory dumps of sensitive data
- File system analysis of stored data
- Side-channel timing attacks
- Brute force attacks on weak PINs

**Integrity Attacks**:
- Modification of stored data
- Share tampering or corruption
- Authentication bypass attempts
- Rollback attacks on security parameters

**Availability Attacks**:
- Data deletion or corruption
- Authentication lockout abuse
- Resource exhaustion attacks
- Application crash exploitation

## Security Architecture Layers

### Layer 1: Cryptographic Core

```
┌─────────────────────────────────────────────────────────┐
│                CRYPTOGRAPHIC LAYER                     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   GF(256)   │  │   Shamir    │  │   Secure    │    │
│  │  Field Ops  │  │  Sharing    │  │   Random    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Security Controls:                                     │
│  • Constant-time operations                            │
│  • Cryptographically secure randomness                 │
│  • Side-channel attack resistance                      │
│  • Mathematical correctness verification               │
└─────────────────────────────────────────────────────────┘
```

**Security Implementation**:

```dart
// Constant-time operations prevent timing attacks
class GF256 {
  // Lookup tables ensure constant execution time
  static final List<int> _mulTable = _generateMultiplicationTable();
  static final List<int> _invTable = _generateInverseTable();
  
  /// Multiplication in constant time via precomputed table
  static int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    
    // Table lookup provides constant-time operation
    final logA = _logTable[a];
    final logB = _logTable[b];
    final logResult = (logA + logB) % 255;
    
    return _expTable[logResult];
  }
  
  /// Constant-time comparison prevents timing analysis
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    
    // Single comparison at end maintains constant time
    return result == 0;
  }
}

// Cryptographically secure random generation
class SecureRandom {
  static final Random _secureRandom = Random.secure();
  
  /// Platform-provided cryptographically secure randomness
  static int nextGF256Element() {
    return _secureRandom.nextInt(256);
  }
  
  /// Ensure non-zero elements for polynomial coefficients
  static int nextNonZeroGF256Element() {
    int value;
    do {
      value = nextGF256Element();
    } while (value == 0);
    return value;
  }
}
```

### Layer 2: Authentication & Access Control

```
┌─────────────────────────────────────────────────────────┐
│               AUTHENTICATION LAYER                     │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   PBKDF2    │  │  Lockout    │  │   Session   │    │
│  │  Hashing    │  │ Protection  │  │ Management  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Security Controls:                                     │
│  • Strong key derivation (PBKDF2)                      │
│  • Progressive lockout protection                      │
│  • Constant-time hash verification                     │
│  • Secure session management                           │
└─────────────────────────────────────────────────────────┘
```

**Security Implementation**:

```dart
// PBKDF2 with device-calibrated iterations
class Pbkdf2CryptoProvider implements IPinCryptoProvider {
  static const int _minIterations = 100000;
  static const int _saltLength = 32;
  
  @override
  Future<PinHash> hashPin(String pin, {int? iterations}) async {
    // Generate cryptographically secure salt
    final salt = Uint8List(_saltLength);
    final random = Random.secure();
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    
    // Use device-calibrated iterations if not specified
    final effectiveIterations = iterations ?? await _getDeviceOptimizedIterations();
    
    // PBKDF2-HMAC-SHA256 key derivation
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: effectiveIterations,
      bits: 256,
    );
    
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    
    final hash = await secretKey.extractBytes();
    
    return PinHash.fromSalt(
      Uint8List.fromList(hash),
      salt,
      effectiveIterations,
      DateTime.now(),
    );
  }
  
  @override
  Future<bool> verifyPin(String pin, PinHash storedHash) async {
    // Derive hash using stored salt and parameters
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: storedHash.iterations,
      bits: 256,
    );
    
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: storedHash.salt,
    );
    
    final derivedHash = await secretKey.extractBytes();
    
    // Constant-time comparison prevents timing attacks
    return constantTimeEquals(
      Uint8List.fromList(derivedHash),
      storedHash.hash,
    );
  }
  
  /// Calibrate PBKDF2 iterations for device performance
  Future<int> _getDeviceOptimizedIterations() async {
    const targetMilliseconds = 250; // Target 250ms for good UX
    const testPin = "0000";
    const testIterations = 10000;
    
    final stopwatch = Stopwatch()..start();
    
    // Test performance with baseline iterations
    await _performTestHash(testPin, testIterations);
    
    stopwatch.stop();
    
    // Scale iterations to achieve target timing
    final scaleFactor = targetMilliseconds / stopwatch.elapsedMilliseconds;
    final optimizedIterations = (testIterations * scaleFactor).round();
    
    // Ensure minimum security threshold
    return math.max(optimizedIterations, _minIterations);
  }
}

// Progressive lockout prevents brute force attacks
class AuthAttemptHistory {
  static const List<Duration> _lockoutDurations = [
    Duration(minutes: 1),   // First lockout
    Duration(minutes: 5),   // Second lockout
    Duration(minutes: 15),  // Third lockout
    Duration(hours: 1),     // Fourth lockout
    Duration(hours: 24),    // Permanent lockout threshold
  ];
  
  bool isLocked() {
    if (_attempts.isEmpty) return false;
    
    final failedAttempts = _getRecentFailedAttempts();
    
    if (failedAttempts.length < 3) return false;
    
    final lockoutLevel = math.min(failedAttempts.length - 3, _lockoutDurations.length - 1);
    final lockoutDuration = _lockoutDurations[lockoutLevel];
    
    final lastFailedAttempt = failedAttempts.last.timestamp;
    final lockoutExpiry = lastFailedAttempt.add(lockoutDuration);
    
    return DateTime.now().isBefore(lockoutExpiry);
  }
}
```

### Layer 3: Data Protection

```
┌─────────────────────────────────────────────────────────┐
│                DATA PROTECTION LAYER                   │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │    XOR      │  │   Secure    │  │    File     │    │
│  │ Encryption  │  │  Deletion   │  │ Permissions │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Security Controls:                                     │
│  • XOR encryption for stored data                      │
│  • Secure multi-pass file deletion                     │
│  • Restrictive file permissions                        │
│  • Integrity verification                              │
└─────────────────────────────────────────────────────────┘
```

**Security Implementation**:

```dart
// Air-gapped storage with encryption
class SecureStorageRepository {
  /// XOR encrypt data for storage obfuscation
  Uint8List _encryptData(Uint8List data) {
    // Derive encryption key from device-specific data
    final deviceKey = _deriveDeviceKey();
    final encrypted = Uint8List(data.length);
    
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ deviceKey[i % deviceKey.length];
    }
    
    return encrypted;
  }
  
  /// Multi-pass secure file deletion
  Future<void> _secureDelete(File file) async {
    if (!await file.exists()) return;
    
    final fileSize = await file.length();
    final random = Random.secure();
    
    // Pass 1: Overwrite with random data
    final randomBuffer = Uint8List(fileSize);
    for (int i = 0; i < randomBuffer.length; i++) {
      randomBuffer[i] = random.nextInt(256);
    }
    await file.writeAsBytes(randomBuffer, flush: true);
    
    // Pass 2: Overwrite with zeros
    final zeroBuffer = Uint8List(fileSize);
    await file.writeAsBytes(zeroBuffer, flush: true);
    
    // Pass 3: Overwrite with ones
    final onesBuffer = Uint8List(fileSize);
    for (int i = 0; i < onesBuffer.length; i++) {
      onesBuffer[i] = 0xFF;
    }
    await file.writeAsBytes(onesBuffer, flush: true);
    
    // Final deletion
    await file.delete();
  }
  
  /// Store data with integrity verification
  Future<void> _storeWithIntegrity(String filename, Uint8List data) async {
    final file = File(await _getSecureFilePath(filename));
    
    // Calculate integrity hash
    final digest = sha256.convert(data);
    final integrityData = Uint8List.fromList([
      ...digest.bytes,
      ...data,
    ]);
    
    // Encrypt and store
    final encryptedData = _encryptData(integrityData);
    
    // Set restrictive permissions (owner only)
    await file.writeAsBytes(encryptedData);
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['600', file.path]);
    }
  }
}
```

### Layer 4: Application Security

```
┌─────────────────────────────────────────────────────────┐
│              APPLICATION SECURITY LAYER                │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Input     │  │   Memory    │  │    UI       │    │
│  │ Validation  │  │ Protection  │  │ Security    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│                                                         │
│  Security Controls:                                     │
│  • Comprehensive input validation                      │
│  • Secure memory handling                              │
│  • UI state protection                                 │
│  • Error handling security                             │
└─────────────────────────────────────────────────────────┘
```

## Security Controls by Domain

### Crypto Domain Security

**Timing Attack Prevention**:
```dart
// All field operations execute in constant time
class GF256 {
  static int lagrangeInterpolate(List<int> xValues, List<int> yValues) {
    // Use constant-time arithmetic throughout
    int result = 0;
    
    for (int i = 0; i < xValues.length; i++) {
      int numerator = 1;
      int denominator = 1;
      
      // Constant-time inner loop
      for (int j = 0; j < xValues.length; j++) {
        if (i == j) continue;
        
        numerator = multiply(numerator, xValues[j]);
        denominator = multiply(denominator, subtract(xValues[j], xValues[i]));
      }
      
      final lagrangeTerm = multiply(
        yValues[i],
        divide(numerator, denominator),
      );
      
      result = add(result, lagrangeTerm);
    }
    
    return result;
  }
}
```

**Share Integrity Protection**:
```dart
class SecureShare extends Share {
  final int checksum;
  
  SecureShare({
    required int x,
    required int y,
    required int threshold,
    required int totalShares,
    String? identifier,
  }) : checksum = _calculateChecksum(x, y, threshold, totalShares),
       super(x: x, y: y, identifier: identifier);
  
  static int _calculateChecksum(int x, int y, int threshold, int totalShares) {
    // Simple XOR-based checksum for integrity verification
    return x ^ y ^ threshold ^ totalShares;
  }
  
  bool hasValidChecksum(int threshold, int totalShares) {
    final expectedChecksum = _calculateChecksum(x, y, threshold, totalShares);
    return checksum == expectedChecksum;
  }
}
```

### Auth Domain Security

**PIN Complexity Requirements**:
```dart
class PinValidator {
  static const int minLength = 4;
  static const int maxLength = 8;
  
  void validatePin(String pin) {
    if (pin.length < minLength) {
      throw PinValidationException('PIN must be at least $minLength digits');
    }
    
    if (pin.length > maxLength) {
      throw PinValidationException('PIN cannot exceed $maxLength digits');
    }
    
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw PinValidationException('PIN must contain only digits');
    }
    
    // Prevent trivial patterns
    if (_isSequentialPattern(pin)) {
      throw PinValidationException('PIN cannot be a sequential pattern');
    }
    
    if (_isRepeatingPattern(pin)) {
      throw PinValidationException('PIN cannot be a repeating pattern');
    }
  }
  
  bool _isSequentialPattern(String pin) {
    if (pin.length < 3) return false;
    
    for (int i = 0; i < pin.length - 2; i++) {
      final digit1 = int.parse(pin[i]);
      final digit2 = int.parse(pin[i + 1]);
      final digit3 = int.parse(pin[i + 2]);
      
      // Check for ascending or descending sequences
      if ((digit2 == digit1 + 1 && digit3 == digit2 + 1) ||
          (digit2 == digit1 - 1 && digit3 == digit2 - 1)) {
        return true;
      }
    }
    
    return false;
  }
}
```

### Presentation Domain Security

**Secure UI State Management**:
```dart
class SecretProvider extends ChangeNotifier {
  String? _reconstructedSecret;
  
  // Secure getter with access control
  String? get reconstructedSecret {
    if (!_isAuthenticated()) {
      throw SecurityException('Authentication required to access secret');
    }
    return _reconstructedSecret;
  }
  
  // Automatic cleanup after timeout
  void _scheduleSecretCleanup() {
    Timer(Duration(minutes: 5), () {
      _clearSensitiveData();
      notifyListeners();
    });
  }
  
  void _clearSensitiveData() {
    // Secure memory cleanup
    if (_reconstructedSecret != null) {
      // Attempt to clear string memory (platform-dependent)
      _reconstructedSecret = null;
      
      // Force garbage collection
      gc();
    }
  }
}
```

## Security Monitoring and Auditing

### Security Event Logging

```dart
class SecurityAuditLog {
  static const String _logFile = 'security_audit.log';
  
  static void logAuthenticationAttempt(String outcome, DateTime timestamp) {
    _writeLogEntry(SecurityEvent(
      type: SecurityEventType.authentication,
      outcome: outcome,
      timestamp: timestamp,
      severity: outcome == 'success' ? Severity.info : Severity.warning,
    ));
  }
  
  static void logCryptographicOperation(String operation, bool success) {
    _writeLogEntry(SecurityEvent(
      type: SecurityEventType.cryptographic,
      operation: operation,
      success: success,
      timestamp: DateTime.now(),
      severity: success ? Severity.info : Severity.error,
    ));
  }
  
  static void logSecurityViolation(String description, Severity severity) {
    _writeLogEntry(SecurityEvent(
      type: SecurityEventType.violation,
      description: description,
      timestamp: DateTime.now(),
      severity: severity,
    ));
  }
}
```

### Runtime Security Checks

```dart
class SecurityMonitor {
  /// Verify application integrity at runtime
  static Future<bool> performIntegrityCheck() async {
    try {
      // Check critical file permissions
      await _verifyFilePermissions();
      
      // Verify cryptographic consistency
      await _verifyCryptographicIntegrity();
      
      // Check for tampering indicators
      await _checkTamperingIndicators();
      
      return true;
    } catch (e) {
      SecurityAuditLog.logSecurityViolation(
        'Integrity check failed: $e',
        Severity.critical,
      );
      return false;
    }
  }
  
  /// Detect potential timing attack attempts
  static void monitorTimingAttacks(Duration operationTime, String operation) {
    const expectedTime = Duration(milliseconds: 250);
    const tolerance = Duration(milliseconds: 50);
    
    if ((operationTime - expectedTime).abs() > tolerance) {
      SecurityAuditLog.logSecurityViolation(
        'Unusual timing for $operation: ${operationTime.inMilliseconds}ms',
        Severity.warning,
      );
    }
  }
}
```

## Compliance and Standards

### Cryptographic Standards Compliance

**NIST Compliance**:
- PBKDF2-HMAC-SHA256 per NIST SP 800-132
- AES consideration for future encryption needs
- Secure random number generation per NIST SP 800-90A

**Algorithm Parameters**:
- PBKDF2 minimum 100,000 iterations
- 256-bit salt for key derivation
- SHA-256 for integrity verification
- GF(256) field for Shamir's Secret Sharing

### Security Review Process

**Regular Security Audits**:
1. Monthly automated security scans
2. Quarterly manual code reviews
3. Annual third-party security assessments
4. Continuous vulnerability monitoring

**Review Checklist**:
- [ ] Cryptographic implementation review
- [ ] Timing attack vulnerability assessment
- [ ] Memory management security verification
- [ ] Input validation completeness check
- [ ] Authentication mechanism review
- [ ] Data protection implementation audit

This security architecture provides comprehensive protection for the SRSecrets application while maintaining usability and performance requirements appropriate for a cryptographic secret management tool.