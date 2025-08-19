# Authentication API Reference

## Overview

This document provides comprehensive API documentation for the Authentication Domain services, including usage examples, error handling patterns, and security considerations for each method.

## Core Interfaces

### IPinService Interface

The primary service interface for PIN authentication operations.

```dart
abstract class IPinService {
  PinRequirements get requirements;
  
  Future<bool> isPinSet();
  Future<PinHash> setPin(String pin);
  Future<PinAuthResult> authenticate(String pin);
  Future<PinHash> changePin(String currentPin, String newPin);
  Future<PinHash> resetPin(String newPin);
  Future<bool> needsUpgrade();
  Future<PinHash> upgradeHash(String pin);
  Future<void> clearAttemptHistory();
  Future<Map<String, dynamic>> getAuthenticationStats();
  Future<Duration?> getLockoutRemaining();
  void validatePin(String pin);
  void dispose();
}
```

---

## PIN Lifecycle Operations

### isPinSet()

**Purpose**: Check if a PIN has been configured for the application.

**Signature**:
```dart
Future<bool> isPinSet()
```

**Returns**: `true` if a PIN hash exists in storage, `false` otherwise.

**Example Usage**:
```dart
bool hasPin = await pinService.isPinSet();
if (!hasPin) {
  // Navigate to PIN setup screen
  navigateToSetup();
} else {
  // Navigate to authentication screen
  navigateToLogin();
}
```

**Error Handling**:
- Returns `false` on storage access errors (fail-safe behavior)
- No exceptions thrown from this method

**Security Considerations**:
- Safe to call repeatedly without security implications
- Does not reveal any information about the PIN itself
- Storage errors default to "no PIN set" state

---

### setPin(String pin)

**Purpose**: Set a new PIN with full security validation and hash generation.

**Signature**:
```dart
Future<PinHash> setPin(String pin)
```

**Parameters**:
- `pin`: The new PIN string to set

**Returns**: `PinHash` object containing the generated hash, salt, and metadata.

**Throws**:
- `PinValidationException`: PIN fails security requirements
- `Exception`: Storage or cryptographic operation failures

**Example Usage**:
```dart
try {
  PinHash hash = await pinService.setPin(userPin);
  print('PIN set successfully with ${hash.iterations} iterations');
  
  // Clear any existing lockout state
  // Navigate to main application
  navigateToHome();
  
} on PinValidationException catch (e) {
  // Display validation errors to user
  showErrors(e.violations);
  
} catch (e) {
  // Handle system errors
  showError('Failed to set PIN: $e');
}
```

**Security Operations**:
1. PIN validation against security requirements
2. Cryptographically secure salt generation (256 bits)
3. PBKDF2-HMAC-SHA256 hashing with calibrated iterations
4. Secure storage of hash with metadata
5. Automatic clearing of authentication attempt history

**Performance**:
- Typical duration: 200-800ms (depending on device performance)
- CPU intensive due to PBKDF2 iterations
- May block UI thread - recommend background execution

---

### authenticate(String pin)

**Purpose**: Authenticate user with PIN and comprehensive lockout protection.

**Signature**:
```dart
Future<PinAuthResult> authenticate(String pin)
```

**Parameters**:
- `pin`: The PIN string to verify

**Returns**: `PinAuthResult` containing authentication result and metadata.

**Example Usage**:
```dart
PinAuthResult result = await pinService.authenticate(userPin);

switch (result.result) {
  case AuthResult.success:
    if (result.requiresUpgrade) {
      // Offer security upgrade
      promptForUpgrade();
    }
    // Grant access to application
    navigateToHome();
    break;
    
  case AuthResult.failure:
    showError('Invalid PIN');
    if (result.remainingAttempts != null) {
      showWarning('${result.remainingAttempts} attempts remaining');
    }
    break;
    
  case AuthResult.lockedOut:
    Duration remaining = result.lockoutRemaining!;
    showLockout('Account locked for ${remaining.inMinutes} minutes');
    break;
    
  case AuthResult.invalidInput:
    showError(result.message);
    break;
}
```

**Result Types**:

#### AuthResult.success
```dart
class PinAuthResult {
  final AuthResult result = AuthResult.success;
  final bool requiresUpgrade;  // Hash needs security parameter upgrade
}
```

#### AuthResult.failure
```dart
class PinAuthResult {
  final AuthResult result = AuthResult.failure;
  final String message;           // Error description
  final int? remainingAttempts;   // Attempts before lockout
}
```

#### AuthResult.lockedOut
```dart
class PinAuthResult {
  final AuthResult result = AuthResult.lockedOut;
  final Duration lockoutRemaining;  // Time until lockout expires
}
```

#### AuthResult.invalidInput
```dart
class PinAuthResult {
  final AuthResult result = AuthResult.invalidInput;
  final String message;  // Input validation error
}
```

**Security Features**:
- Constant-time PIN verification (prevents timing attacks)
- Progressive lockout enforcement
- Comprehensive attempt logging
- Automatic hash upgrade detection
- Fail-safe error handling

---

### changePin(String currentPin, String newPin)

**Purpose**: Change existing PIN with current PIN verification.

**Signature**:
```dart
Future<PinHash> changePin(String currentPin, String newPin)
```

**Parameters**:
- `currentPin`: Current PIN for verification
- `newPin`: New PIN to set

**Returns**: `PinHash` object for the new PIN.

**Throws**:
- `PinAuthenticationException`: Current PIN verification failed
- `PinValidationException`: New PIN fails security requirements
- `Exception`: Storage or cryptographic operation failures

**Example Usage**:
```dart
try {
  PinHash newHash = await pinService.changePin(currentPin, newPin);
  showSuccess('PIN changed successfully');
  
  // Optionally log the user out to re-authenticate
  navigateToLogin();
  
} on PinAuthenticationException catch (e) {
  if (e.lockoutRemaining != null) {
    showLockout('Account locked for ${e.lockoutRemaining!.inMinutes} minutes');
  } else {
    showError('Current PIN is incorrect');
  }
  
} on PinValidationException catch (e) {
  showErrors(e.violations);
  
} catch (e) {
  showError('Failed to change PIN: $e');
}
```

**Security Process**:
1. Current PIN authentication (full lockout protection)
2. New PIN validation against security requirements
3. New hash generation with fresh salt and current parameters
4. Atomic replacement of stored hash
5. Authentication attempt history clearing

---

### resetPin(String newPin)

**Purpose**: Administrative PIN reset without current PIN verification.

**Signature**:
```dart
Future<PinHash> resetPin(String newPin)
```

**Parameters**:
- `newPin`: New PIN to set

**Returns**: `PinHash` object for the new PIN.

**Throws**:
- `PinValidationException`: New PIN fails security requirements
- `Exception`: Storage or cryptographic operation failures

**Security Warning**: This method bypasses authentication and should only be used in specific scenarios (e.g., forgot PIN recovery).

**Example Usage**:
```dart
try {
  // Show appropriate warnings about data loss
  bool confirmed = await showResetWarning();
  if (!confirmed) return;
  
  PinHash newHash = await pinService.resetPin(newPin);
  showSuccess('PIN reset successfully');
  
  // Clear any application data that was protected by old PIN
  await clearProtectedData();
  
  navigateToLogin();
  
} on PinValidationException catch (e) {
  showErrors(e.violations);
} catch (e) {
  showError('Failed to reset PIN: $e');
}
```

**Security Operations**:
1. Complete clearing of authentication attempt history
2. New PIN validation
3. Fresh hash generation with new salt
4. Secure deletion of all previous authentication data

---

## Security and Validation

### validatePin(String pin)

**Purpose**: Validate PIN against security requirements without storing or hashing.

**Signature**:
```dart
void validatePin(String pin)
```

**Parameters**:
- `pin`: PIN string to validate

**Throws**:
- `PinValidationException`: PIN fails one or more security requirements

**Example Usage**:
```dart
void onPinChanged(String pin) {
  try {
    pinService.validatePin(pin);
    // PIN is valid - update UI to show acceptance
    setValidationState(ValidationState.valid);
    
  } on PinValidationException catch (e) {
    // Show validation errors in real-time
    setValidationErrors(e.violations);
    setValidationState(ValidationState.invalid);
  }
}
```

**Validation Rules**:
- **Length**: 4-12 characters
- **Character Set**: Digits only (configurable)
- **Common Patterns**: Prevents 1234, 0000, etc.
- **Sequential Patterns**: Prevents 123, 321, etc.
- **Repeating Patterns**: Prevents 1111, 2222, etc.
- **Date Patterns**: Prevents DDMM, YYYY, etc.

**PinValidationException Structure**:
```dart
class PinValidationException implements Exception {
  final String message;
  final List<String> violations;
  
  // Example violations:
  // - "PIN must be at least 4 characters"
  // - "PIN cannot contain sequential digits"
  // - "PIN is too common and easily guessed"
}
```

---

### needsUpgrade()

**Purpose**: Check if stored PIN hash needs security parameter upgrade.

**Signature**:
```dart
Future<bool> needsUpgrade()
```

**Returns**: `true` if hash should be upgraded, `false` otherwise.

**Example Usage**:
```dart
if (await pinService.needsUpgrade()) {
  showUpgradePrompt(
    'Security improvements are available. Upgrade your PIN security?',
    onAccept: () => promptForUpgrade(),
    onDefer: () => remindLater(),
  );
}
```

**Upgrade Triggers**:
- Iteration count below current minimum (100,000)
- Hash algorithm changes (future compatibility)
- Salt length below current standard (256 bits)
- Schema version changes

---

### upgradeHash(String pin)

**Purpose**: Upgrade existing PIN hash to current security parameters.

**Signature**:
```dart
Future<PinHash> upgradeHash(String pin)
```

**Parameters**:
- `pin`: Current PIN for verification and re-hashing

**Returns**: `PinHash` object with upgraded parameters.

**Throws**:
- `PinAuthenticationException`: PIN verification failed
- `Exception`: Storage or cryptographic operation failures

**Example Usage**:
```dart
try {
  PinHash upgradedHash = await pinService.upgradeHash(currentPin);
  showSuccess('PIN security upgraded successfully');
  
} on PinAuthenticationException catch (e) {
  showError('PIN verification failed during upgrade');
} catch (e) {
  showError('Upgrade failed: $e');
}
```

**Upgrade Process**:
1. Current PIN verification with existing parameters
2. Re-hashing with current security parameters
3. Atomic replacement of stored hash
4. Preservation of authentication attempt history

---

## Monitoring and Diagnostics

### getAuthenticationStats()

**Purpose**: Retrieve comprehensive authentication statistics and metrics.

**Signature**:
```dart
Future<Map<String, dynamic>> getAuthenticationStats()
```

**Returns**: Map containing authentication statistics and system state.

**Example Usage**:
```dart
Map<String, dynamic> stats = await pinService.getAuthenticationStats();

print('Total attempts: ${stats['totalAttempts']}');
print('Success rate: ${stats['successRate']}%');
print('Current lockout: ${stats['isLockedOut']}');
print('Recent failures: ${stats['recentFailureCount']}');

// Use for monitoring dashboards or debugging
if (stats['wouldTriggerLockout']) {
  showWarning('Next failure will lock account');
}
```

**Statistics Structure**:
```dart
{
  'totalAttempts': 156,
  'successfulAttempts': 142,
  'failedAttempts': 14,
  'successRate': 91.0,
  'isLockedOut': false,
  'lockoutRemaining': null,  // seconds, or null if not locked
  'recentFailureCount': 2,
  'wouldTriggerLockout': false,
  'lastSuccessTimestamp': '2024-01-15T10:30:00.000Z',
  'lastFailureTimestamp': '2024-01-15T09:15:00.000Z',
  'lockoutHistory': [
    {
      'timestamp': '2024-01-10T14:20:00.000Z',
      'duration': 1800,  // seconds
      'triggerCount': 5
    }
  ]
}
```

---

### getLockoutRemaining()

**Purpose**: Get remaining lockout duration if account is currently locked.

**Signature**:
```dart
Future<Duration?> getLockoutRemaining()
```

**Returns**: `Duration` if locked, `null` if not locked.

**Example Usage**:
```dart
Duration? remaining = await pinService.getLockoutRemaining();
if (remaining != null) {
  startLockoutTimer(remaining);
  updateUI('Account locked for ${remaining.inMinutes} minutes');
} else {
  enableAuthenticationUI();
}
```

**Lockout Schedule**:
- **5 failures**: 30 seconds
- **10 failures**: 5 minutes
- **15 failures**: 30 minutes
- **20+ failures**: Exponential backoff (max 24 hours)

---

### clearAttemptHistory()

**Purpose**: Reset authentication attempt history (administrative operation).

**Signature**:
```dart
Future<void> clearAttemptHistory()
```

**Throws**:
- `Exception`: Storage operation failures

**Example Usage**:
```dart
try {
  await pinService.clearAttemptHistory();
  showSuccess('Authentication history cleared');
  
  // Update UI to reflect cleared lockout state
  enableAuthenticationUI();
  
} catch (e) {
  showError('Failed to clear history: $e');
}
```

**Security Implications**:
- Immediately clears any active lockout
- Removes all authentication attempt records
- Should be restricted to administrative users only
- Consider logging this action for security audit

---

## Error Handling Patterns

### Exception Hierarchy

```dart
// Base authentication exception
abstract class PinException implements Exception {
  String get message;
}

// PIN validation failures
class PinValidationException extends PinException {
  final List<String> violations;
  String get message => 'PIN validation failed';
}

// Authentication failures
class PinAuthenticationException extends PinException {
  final AuthResult result;
  final Duration? lockoutRemaining;
  String get message => 'PIN authentication failed';
}

// Storage or system failures
class PinSystemException extends PinException {
  final String cause;
  String get message => 'PIN system error: $cause';
}
```

### Error Handling Best Practices

```dart
// Comprehensive error handling pattern
Future<void> handlePinOperation() async {
  try {
    await pinService.authenticate(userPin);
    
  } on PinValidationException catch (e) {
    // Handle input validation errors
    showValidationErrors(e.violations);
    
  } on PinAuthenticationException catch (e) {
    // Handle authentication-specific errors
    switch (e.result) {
      case AuthResult.failure:
        showAuthError('Invalid PIN');
        break;
      case AuthResult.lockedOut:
        showLockoutError(e.lockoutRemaining!);
        break;
    }
    
  } on PinSystemException catch (e) {
    // Handle system/storage errors
    showSystemError('System error: ${e.cause}');
    logError(e);
    
  } catch (e) {
    // Handle unexpected errors
    showGenericError('Unexpected error occurred');
    logError(e);
  }
}
```

---

## Threading and Concurrency

### Thread Safety

**Thread-Safe Operations**:
- All public methods are async and thread-safe
- Internal synchronization prevents concurrent modification
- Storage operations are atomic where possible

**Usage Guidelines**:
```dart
// Safe: Multiple authentication attempts are serialized
Future.wait([
  pinService.authenticate(pin1),
  pinService.authenticate(pin2),
]); // Each operation will complete individually

// Safe: PIN change operations are atomic
await pinService.changePin(oldPin, newPin);
```

**Concurrency Considerations**:
- PIN hash modifications are atomic (no partial updates)
- Attempt history updates are serialized
- Storage repository handles file locking internally

---

## Performance Guidelines

### Operation Performance

**Typical Latencies**:
```
isPinSet():           < 50ms
setPin():            200-800ms (PBKDF2 intensive)
authenticate():      200-800ms (PBKDF2 intensive)
changePin():         400-1600ms (2x PBKDF2 operations)
validatePin():        < 10ms
getAuthenticationStats(): < 50ms
```

**Optimization Strategies**:
```dart
// Pre-validate before expensive operations
try {
  pinService.validatePin(pin);
  // Only proceed with expensive setPin if validation passes
  await pinService.setPin(pin);
} on PinValidationException catch (e) {
  // Handle validation errors immediately
  showErrors(e.violations);
}

// Background execution for UI responsiveness
Future<void> authenticateInBackground(String pin) async {
  showLoadingIndicator();
  
  try {
    PinAuthResult result = await pinService.authenticate(pin);
    handleAuthResult(result);
  } finally {
    hideLoadingIndicator();
  }
}
```

### Memory Management

**Memory Usage**:
- Peak memory during PBKDF2: ~5-10MB
- Persistent memory: < 1MB
- Automatic cleanup of sensitive data

**Resource Cleanup**:
```dart
// Proper service cleanup
@override
void dispose() {
  pinService.dispose();
  super.dispose();
}
```

---

*This API reference provides complete documentation for integrating with the SRSecrets authentication system. Follow the patterns and examples provided to ensure secure and reliable authentication implementation.*