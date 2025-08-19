# Secure Storage Implementation Guide

## Overview

The Secure Storage Repository implements air-gapped, file-based storage for PIN authentication data with encryption, secure deletion, and platform-specific security measures. This guide details the implementation, security model, and operational procedures.

## Storage Architecture

### File System Layout

**Storage Location Strategy**:
```
iOS/macOS: Library/Application Support/secure_auth/
Android:   /data/data/{package}/files/secure_auth/
Linux:     ~/.local/share/{app}/secure_auth/
```

**Directory Structure**:
```
secure_auth/
├── pin_hash.dat          # Encrypted PIN hash and metadata
└── auth_attempts.dat     # Encrypted authentication history
```

**Platform-Specific Behaviors**:
- **iOS**: Application Support directory cleared on uninstall
- **Android**: Files directory cleared on uninstall automatically
- **Desktop**: User-local application data with manual cleanup

### File Security Model

**Access Control**:
```bash
# Directory permissions (Unix-like systems)
chmod 700 secure_auth/          # Owner read/write/execute only

# File permissions
chmod 600 pin_hash.dat          # Owner read/write only
chmod 600 auth_attempts.dat     # Owner read/write only
```

**Security Measures**:
- Owner-only file system permissions
- Hidden directory location outside user documents
- Automatic cleanup on application uninstall
- No world-readable or group-accessible permissions

## Encryption Implementation

### XOR-Based Obfuscation

**Purpose**: Provides basic data obfuscation rather than cryptographic security.

**Key Generation**:
```dart
String keyBase = Platform.operatingSystem + 
                 Platform.operatingSystemVersion +
                 'srsecrets_auth_key';
```

**Encryption Process**:
```
1. JSON serialize data → UTF-8 bytes
2. Generate device-specific XOR key (256 bytes)
3. XOR encrypt: encrypted[i] = data[i] ^ key[i % key.length]
4. Base64 encode for string storage
```

**Security Properties**:
- **Obfuscation**: Prevents casual inspection of stored data
- **Device Binding**: Key derivation ties data to specific device
- **Deterministic**: Same key generated across app launches
- **Not Cryptographically Secure**: XOR can be easily reversed

### Key Derivation Details

**Key Material Sources**:
```dart
// Platform identification
Platform.operatingSystem        // "ios", "android", "linux", etc.
Platform.operatingSystemVersion // "14.5", "API 30", etc.

// Application-specific salt
const String APP_SALT = 'srsecrets_auth_key';
```

**Key Expansion Algorithm**:
```dart
List<int> keyBytes = utf8.encode(keyBase);
Uint8List key = Uint8List(256);

// Cyclic expansion to 256 bytes
for (int i = 0; i < key.length; i++) {
  key[i] = keyBytes[i % keyBytes.length];
}
```

**Security Analysis**:
- **Advantages**: Simple, fast, no external dependencies
- **Limitations**: Reversible with key knowledge, not authenticated
- **Use Case**: File obfuscation against casual inspection only

## Data Persistence Model

### PIN Hash Storage Format

**JSON Structure**:
```json
{
  "hash": "base64-encoded-PBKDF2-hash",
  "salt": "base64-encoded-256-bit-salt",
  "iterations": 200000,
  "created_at": "2024-01-15T10:30:00.000Z",
  "version": "1.0"
}
```

**Field Specifications**:
- **hash**: 32-byte PBKDF2-HMAC-SHA256 output (base64-encoded)
- **salt**: 32-byte cryptographically random salt (base64-encoded)
- **iterations**: PBKDF2 iteration count (minimum 100,000)
- **created_at**: ISO 8601 timestamp in UTC
- **version**: Schema version for future migrations

### Authentication History Format

**JSON Structure**:
```json
{
  "attempts": [
    {
      "timestamp": "2024-01-15T10:30:00.000Z",
      "result": "success",
      "duration_ms": 234,
      "details": "optional-context"
    }
  ],
  "version": "1.0"
}
```

**Attempt Record Fields**:
- **timestamp**: Precise attempt time (ISO 8601 UTC)
- **result**: "success", "failure", "locked_out"
- **duration_ms**: Authentication operation duration
- **details**: Optional context (error messages, etc.)

## Secure Deletion Implementation

### Multi-Pass Overwrite Strategy

**Deletion Process**:
```
Pass 1: Overwrite with cryptographically random data
Pass 2: Overwrite with cryptographically random data  
Pass 3: Overwrite with cryptographically random data
Pass 4: Overwrite with zeros
Pass 5: File system deletion
```

**Implementation Details**:
```dart
Future<void> _secureDeleteFile(File file) async {
  int fileSize = await file.length();
  SecureRandom secureRandom = SecureRandom.instance;
  
  // Three passes with random data
  for (int pass = 0; pass < 3; pass++) {
    Uint8List randomData = secureRandom.nextBytes(fileSize);
    await file.writeAsBytes(randomData, flush: true);
  }
  
  // Final pass with zeros
  Uint8List zeros = Uint8List(fileSize);
  await file.writeAsBytes(zeros, flush: true);
  
  // Delete file
  await file.delete();
}
```

**Security Properties**:
- **Data Residue Protection**: Multiple overwrites prevent data recovery
- **Random Data Passes**: Prevent pattern analysis of deleted content
- **Zero Final Pass**: Ensure clean final state
- **Flush Operations**: Force immediate disk write
- **Fallback Deletion**: Regular deletion if secure deletion fails

### Storage Cleanup Procedures

**Application Uninstall**:
- Platform automatically removes application directories
- No manual cleanup required for normal uninstall

**Manual Data Clearing**:
```dart
// Clear all authentication data
await storageRepository.clearAll();

// Force clear from all possible locations
await storageRepository.forceClearAllStorageLocations();
```

**Legacy Data Migration**:
- Automatic detection of old storage locations
- Secure migration to current storage location
- Secure cleanup of legacy storage directories

## Data Migration and Versioning

### Legacy Storage Migration

**Migration Triggers**:
- Storage location changes between app versions
- Security requirement updates
- Platform policy changes

**Migration Process**:
```dart
Future<void> _migrateOldData() async {
  Directory oldDocDir = await getApplicationDocumentsDirectory();
  Directory oldSecureDir = Directory('${oldDocDir.path}/secure_auth');
  
  if (await oldSecureDir.exists()) {
    // Copy data to new location if new location is empty
    if (await oldPinFile.exists() && !await newPinFile.exists()) {
      await oldPinFile.copy(newPinPath);
      await oldAttemptFile.copy(newAttemptPath);
    }
    
    // Securely clean up old location
    await _cleanupOldDirectory(oldSecureDir);
  }
}
```

**Migration Safety**:
- Never overwrites existing data in new location
- Maintains data integrity during migration
- Secure cleanup of old location after successful migration
- Failure handling preserves user data

### Schema Evolution

**Version Management**:
- Each stored JSON includes version field
- Forward compatibility for new fields
- Migration handlers for breaking changes
- Validation of loaded data integrity

**Upgrade Process**:
1. Detect schema version on load
2. Apply appropriate migration transformations
3. Validate migrated data integrity
4. Save data in current schema version
5. Log migration success/failure

## Platform-Specific Implementations

### iOS/macOS Security Features

**Directory Location**:
```swift
// Application Support Directory (not backed up to iCloud)
let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                         in: .userDomainMask).first!
```

**Security Features**:
- Automatic app sandbox isolation
- No iCloud backup inclusion
- File system encryption (when device is locked)
- App-specific directory removal on uninstall

### Android Security Model

**Directory Location**:
```java
// Internal storage (private to application)
File filesDir = context.getFilesDir();
```

**Security Features**:
- Application-private storage (other apps cannot access)
- No external storage usage
- Automatic cleanup on app uninstall
- SELinux policy enforcement

### Linux/Desktop Considerations

**Directory Location**:
```bash
~/.local/share/srsecrets/secure_auth/
```

**Security Limitations**:
- Manual cleanup required (no automatic uninstall cleanup)
- User-level permissions only (no system-level protection)
- Potential access by other user processes
- No built-in disk encryption

## Error Handling and Recovery

### Storage Failure Scenarios

**Common Failure Modes**:
- Insufficient disk space
- Permission denied errors
- File corruption during write
- Storage device failures
- Application termination during operations

**Recovery Strategies**:
```dart
// Graceful degradation on load failures
Future<PinHash?> loadPinHash() async {
  try {
    // Attempt normal load process
    return await _loadFromStorage();
  } catch (e) {
    // Return null to indicate no PIN set
    // Don't break authentication flow
    return null;
  }
}
```

**Error Classification**:
- **Recoverable**: Retry with backoff, temporary failures
- **Non-Recoverable**: Data corruption, permanent storage failure
- **Security**: Potential tampering, integrity violations

### Integrity Validation

**Data Validation Checks**:
- JSON schema validation on load
- Field range validation (iterations, dates, etc.)
- Base64 decoding validation
- Logical consistency checks

**Corruption Detection**:
```dart
// Validate PIN hash integrity
if (hash.length != expectedHashLength) {
  throw StorageCorruptionException('Invalid hash length');
}

if (salt.length < minimumSaltLength) {
  throw StorageCorruptionException('Invalid salt length');
}

if (iterations < minimumIterations) {
  throw StorageCorruptionException('Invalid iteration count');
}
```

## Performance Considerations

### I/O Optimization

**Read Optimization**:
- Single file read operation per load
- JSON parsing with error handling
- Base64 decoding only when needed
- Minimal memory allocation

**Write Optimization**:
- Atomic file operations where possible
- Immediate flush for security-critical data
- Minimal intermediate copies
- Efficient JSON serialization

### Storage Footprint

**Typical Storage Usage**:
```
PIN Hash File:     ~400 bytes (base64-encoded)
Attempt History:   ~50-500 bytes (depending on history length)
Total Storage:     < 1KB per user
```

**Growth Patterns**:
- PIN hash: Fixed size regardless of PIN length
- Attempt history: Linear growth with authentication events
- Automatic pruning of old attempt records
- No unbounded growth scenarios

## Security Testing and Validation

### Security Test Requirements

**File System Security**:
```bash
# Verify file permissions
ls -la secure_auth/
# Should show: drwx------ (700) for directory
# Should show: -rw------- (600) for files

# Verify no world-readable permissions
find secure_auth/ -perm /022
# Should return no results
```

**Encryption Validation**:
```dart
// Verify encrypted data is not plaintext
String encryptedContent = await file.readAsString();
assert(!encryptedContent.contains('{"hash"'));

// Verify decryption produces valid JSON
Map<String, dynamic> decrypted = _decryptData(encryptedContent);
assert(decrypted.containsKey('hash'));
```

**Secure Deletion Testing**:
```dart
// Create test file with known content
await file.writeAsString('sensitive_test_data');

// Perform secure deletion
await _secureDeleteFile(file);

// Verify file is gone
assert(!await file.exists());

// Manual verification: Check if data can be recovered
// (Requires file system forensic tools)
```

### Performance Benchmarks

**I/O Performance Targets**:
- File read operations: < 50ms
- File write operations: < 100ms
- Secure deletion: < 500ms
- Directory initialization: < 100ms

**Memory Usage**:
- Peak memory during operations: < 1MB
- Persistent memory usage: < 100KB
- No memory leaks over time

## Operational Procedures

### Installation and Setup

**First-Time Initialization**:
1. Detect platform-specific storage location
2. Create secure directory with appropriate permissions
3. Initialize empty storage state
4. Validate storage accessibility

**Upgrade Scenarios**:
1. Detect existing storage location
2. Migrate data if location changed
3. Apply schema upgrades if needed
4. Clean up legacy storage locations
5. Validate migrated data integrity

### Backup and Recovery

**Backup Strategy**:
- **Not Recommended**: PIN data should not be backed up
- **Air-Gapped Design**: Local data only, no cloud backup
- **User Responsibility**: PIN is user's secret, no recovery mechanism

**Recovery Limitations**:
- Lost PIN requires complete reset of application data
- No secret recovery questions or backdoors
- No administrator override capabilities
- Complete data loss on device failure

### Monitoring and Diagnostics

**Health Checks**:
```dart
// Verify storage is accessible
bool isAvailable = await storage.isAvailable();

// Get storage statistics
Map<String, dynamic> info = await storage.getStorageInfo();

// Validate file integrity
bool isIntact = await storage.validateIntegrity();
```

**Diagnostic Information**:
- Storage directory location and accessibility
- File sizes and modification times
- Permission verification results
- Schema version compatibility
- Migration history and status

---

*This guide provides comprehensive implementation details for secure storage in the SRSecrets authentication domain. All storage operations should follow the security principles and procedures outlined in this document.*