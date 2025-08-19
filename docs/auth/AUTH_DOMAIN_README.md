# Authentication Domain Architecture

## Overview

The Authentication Domain provides secure PIN-based authentication for the SRSecrets application, implementing air-gapped security principles with no network connectivity. The domain ensures cryptographic secret access is protected by robust PIN authentication with progressive lockout mechanisms.

## Architecture Principles

### Air-Gapped Security Design
- **No Network Connectivity**: All authentication data remains local to the device
- **Secure Local Storage**: File-based encryption with restricted permissions
- **Data Isolation**: Authentication data stored separately from application data
- **Secure Deletion**: Multi-pass overwriting before file removal

### Defense in Depth
- **Multiple Security Layers**: PIN validation, progressive lockout, timing attack protection
- **Fail-Safe Design**: Security failures default to lockout state
- **Audit Trail**: Complete authentication attempt tracking
- **Memory Protection**: Secure clearing of sensitive data

## Core Components

### 1. PIN Service Layer (`PinServiceImpl`)

**Purpose**: Primary orchestration layer implementing business logic and security policies.

**Key Responsibilities**:
- PIN lifecycle management (set, change, reset, upgrade)
- Authentication with comprehensive security validation
- Progressive lockout enforcement
- Security parameter validation and upgrade detection

**Security Features**:
- PIN complexity validation against multiple attack vectors
- Constant-time authentication operations
- Comprehensive attempt logging and analysis
- Automatic security parameter upgrades

### 2. Cryptographic Provider (`Pbkdf2CryptoProvider`)

**Purpose**: PBKDF2-HMAC-SHA256 implementation providing cryptographic security primitives.

**Technical Specifications**:
- **Algorithm**: PBKDF2-HMAC-SHA256
- **Salt Length**: 256 bits (32 bytes)
- **Hash Length**: 256 bits (32 bytes)
- **Minimum Iterations**: 100,000 (NIST recommended)
- **Default Iterations**: 200,000
- **Timing Protection**: Constant-time comparison operations

**Security Guarantees**:
- Cryptographically secure salt generation
- Resistance to rainbow table attacks
- Timing attack protection through constant-time operations
- Memory security with explicit data clearing

### 3. Secure Storage Repository (`SecureStorageRepository`)

**Purpose**: Air-gapped file-based storage with encryption and secure deletion capabilities.

**Storage Architecture**:
- **Storage Location**: Platform-specific application support directories
- **File Permissions**: Owner-only access (700/600 on Unix systems)
- **Encryption**: XOR-based obfuscation with device-derived keys
- **Secure Deletion**: Multi-pass overwriting with random data

**Data Protection**:
- PIN hash storage with metadata preservation
- Authentication attempt history tracking
- Automatic data migration from legacy storage locations
- Complete storage lifecycle management

### 4. Authentication Models

#### PinHash Model
**Purpose**: Immutable value object representing securely hashed PIN data.

**Components**:
- **Hash**: 256-bit PBKDF2-derived key
- **Salt**: 256-bit cryptographically random salt
- **Iterations**: PBKDF2 iteration count
- **Metadata**: Creation timestamp and version information

#### AuthAttempt & AuthAttemptHistory
**Purpose**: Comprehensive tracking of authentication attempts with lockout logic.

**Tracking Capabilities**:
- Individual attempt recording with precise timing
- Progressive lockout calculation with exponential backoff
- Security event analysis and pattern detection
- Configurable lockout policies and recovery mechanisms

## PIN Security Framework

### PIN Validation Rules

**Length Requirements**:
- Minimum: 4 characters
- Maximum: 12 characters
- Digits-only enforcement (configurable)

**Pattern Prevention**:
- Common PIN detection (1234, 0000, etc.)
- Sequential digit prevention (123, 321)
- Repeating digit limits (max 2 consecutive)
- Date pattern detection (DDMM, YYYY patterns)

**Security Levels**:
- **Basic**: Length validation only
- **Standard**: Common pattern prevention
- **Secure**: Comprehensive validation with all checks enabled

### Progressive Lockout System

**Lockout Thresholds**:
- **5 failed attempts**: 30-second lockout
- **10 failed attempts**: 5-minute lockout
- **15 failed attempts**: 30-minute lockout
- **20+ failed attempts**: Exponential backoff up to 24 hours

**Lockout Features**:
- Automatic lockout detection and enforcement
- Remaining time calculation and display
- Administrative reset capabilities
- Attempt history analysis and reporting

## PBKDF2 Implementation Details

### Cryptographic Parameters

**PBKDF2-HMAC-SHA256 Configuration**:
```
Salt Generation: SecureRandom (256 bits)
Iteration Count: 200,000 (calibrated)
Output Length: 256 bits
Hash Function: SHA-256
MAC Function: HMAC-SHA-256
```

**Security Justifications**:
- **200,000 iterations**: Exceeds NIST SP 800-63B recommendations
- **256-bit salt**: Prevents rainbow table attacks
- **SHA-256**: FIPS 140-2 approved hash function
- **Constant-time comparison**: Prevents timing attacks

### Performance Calibration

**Iteration Calibration**:
- Device-specific performance benchmarking
- Target authentication time: 500ms
- Minimum security floor: 100,000 iterations
- Automatic upgrade detection for legacy hashes

## Integration Patterns

### Service Initialization
```dart
// Dependency injection pattern
final IPinCryptoProvider cryptoProvider = Pbkdf2CryptoProvider();
final IPinStorageRepository storage = SecureStorageRepository();
final IPinService pinService = PinServiceImpl(
  storageRepository: storage,
  cryptoProvider: cryptoProvider,
  requirements: PinRequirements.secure,
);
```

### Authentication Flow
```dart
// Complete authentication with lockout checking
PinAuthResult result = await pinService.authenticate(userPin);

switch (result.result) {
  case AuthResult.success:
    // Grant access, check for hash upgrades
    if (result.requiresUpgrade) {
      // Prompt for hash upgrade
    }
    break;
  case AuthResult.failure:
    // Display failure message with remaining attempts
    break;
  case AuthResult.lockedOut:
    // Display lockout duration and wait
    break;
}
```

### PIN Management
```dart
// PIN lifecycle operations
await pinService.setPin(newPin);           // Initial setup
await pinService.changePin(current, new);  // Authenticated change
await pinService.resetPin(newPin);         // Administrative reset
await pinService.upgradeHash(currentPin);  // Security upgrade
```

## Security Considerations

### Threat Model
**Addressed Threats**:
- Brute force attacks (progressive lockout)
- Dictionary attacks (PBKDF2 with high iterations)
- Rainbow table attacks (cryptographic salt)
- Timing attacks (constant-time operations)
- Physical device access (encrypted storage)
- Memory dumps (secure data clearing)

**Assumptions**:
- Device physical security is user responsibility
- Operating system security boundaries are trusted
- Hardware-based secure enclaves are not available
- Application isolation is enforced by the platform

### Security Limitations
**Known Limitations**:
- XOR encryption provides obfuscation, not cryptographic security
- Memory clearing is best-effort in garbage-collected environments
- Platform-specific security features may not be available
- Side-channel attacks against PBKDF2 implementation

**Mitigation Strategies**:
- Multiple defense layers reduce single-point failures
- Progressive lockout limits practical attack windows
- Air-gapped design eliminates network attack vectors
- Regular security parameter upgrades maintain protection

## Maintenance and Upgrades

### Security Parameter Evolution
**Upgrade Triggers**:
- New NIST recommendations for iteration counts
- Discovered weaknesses in current parameters
- Improved device performance enabling higher security
- Regulatory compliance requirements

**Upgrade Process**:
1. Detection of legacy parameters during authentication
2. User notification of available security improvements
3. Authenticated upgrade with current PIN
4. Transparent migration to new parameters
5. Verification of upgrade success

### Monitoring and Observability
**Key Metrics**:
- Authentication success/failure rates
- Lockout frequency and duration
- Hash upgrade completion rates
- Storage integrity and performance
- Security parameter distribution

## Testing and Validation

### Security Test Requirements
**Test Categories**:
- **Cryptographic Validation**: PBKDF2 implementation correctness
- **Timing Attack Resistance**: Constant-time operation verification
- **Lockout Logic**: Progressive enforcement and recovery
- **Storage Security**: Encryption and secure deletion
- **PIN Validation**: Pattern detection and security rules

### Performance Benchmarks
**Performance Targets**:
- Authentication latency: < 1 second
- Storage operations: < 100ms
- Memory usage: < 50MB peak
- Storage footprint: < 1KB per user

## Compliance and Standards

### Cryptographic Standards
**Compliance**:
- NIST SP 800-63B: Digital Identity Guidelines
- FIPS 140-2: Cryptographic module validation
- RFC 2898: PKCS #5 PBKDF2 specification
- RFC 6234: US Secure Hash Algorithms

### Privacy and Security
**Requirements**:
- GDPR Article 32: Security of processing
- ISO 27001: Information security management
- OWASP Mobile Security: Mobile application security
- Platform security guidelines (iOS/Android)

---

*This document serves as the authoritative reference for the Authentication Domain architecture and implementation. All development and security decisions should align with the principles and specifications outlined herein.*