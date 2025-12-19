/// PIN Authentication Service Interface
/// 
/// Defines the contract for PIN-based authentication following DDD principles.
/// Provides secure PIN operations with PBKDF2 hashing and lockout protection.
library;

import 'dart:typed_data';
import '../models/pin_hash.dart';
import '../models/auth_attempt.dart';

/// Exception thrown when PIN authentication fails
class PinAuthenticationException implements Exception {
  final String message;
  final AuthResult result;
  final Duration? lockoutRemaining;
  
  const PinAuthenticationException({
    required this.message,
    required this.result,
    this.lockoutRemaining,
  });
  
  @override
  String toString() => 'PinAuthenticationException: $message';
}

/// Exception thrown when PIN validation fails
class PinValidationException implements Exception {
  final String message;
  final List<String> violations;
  
  const PinValidationException({
    required this.message,
    required this.violations,
  });
  
  @override
  String toString() => 'PinValidationException: $message';
}

/// Result of PIN authentication attempt
class PinAuthResult {
  final bool success;
  final AuthResult result;
  final String? message;
  final Duration? lockoutRemaining;
  final int? remainingAttempts;
  final bool requiresUpgrade;
  
  const PinAuthResult({
    required this.success,
    required this.result,
    this.message,
    this.lockoutRemaining,
    this.remainingAttempts,
    this.requiresUpgrade = false,
  });
  
  factory PinAuthResult.success({bool requiresUpgrade = false}) {
    return PinAuthResult(
      success: true,
      result: AuthResult.success,
      requiresUpgrade: requiresUpgrade,
    );
  }
  
  factory PinAuthResult.failure({
    required String message,
    int? remainingAttempts,
  }) {
    return PinAuthResult(
      success: false,
      result: AuthResult.failure,
      message: message,
      remainingAttempts: remainingAttempts,
    );
  }
  
  factory PinAuthResult.lockedOut({
    required Duration lockoutRemaining,
  }) {
    return PinAuthResult(
      success: false,
      result: AuthResult.lockedOut,
      message: 'Account locked due to too many failed attempts',
      lockoutRemaining: lockoutRemaining,
    );
  }
  
  factory PinAuthResult.invalidInput(String message) {
    return PinAuthResult(
      success: false,
      result: AuthResult.invalidInput,
      message: message,
    );
  }
}

/// PIN validation requirements
class PinRequirements {
  final int minLength;
  final int maxLength;
  final bool requireDigitsOnly;
  final bool preventCommonPatterns;
  final bool preventRepeatingDigits;
  final bool preventSequentialDigits;
  
  const PinRequirements({
    this.minLength = 6,
    this.maxLength = 12,
    this.requireDigitsOnly = true,
    this.preventCommonPatterns = true,
    this.preventRepeatingDigits = true,
    this.preventSequentialDigits = true,
  });
  
  /// Default secure requirements - allows 4-8 digit PINs
  static const PinRequirements secure = PinRequirements(
    minLength: 4,
    maxLength: 8,
    requireDigitsOnly: true,
    preventCommonPatterns: true,
    preventRepeatingDigits: true,
    preventSequentialDigits: true,
  );
  
  /// Relaxed requirements for testing
  static const PinRequirements relaxed = PinRequirements(
    minLength: 4,
    maxLength: 8,
    preventCommonPatterns: false,
    preventRepeatingDigits: false,
    preventSequentialDigits: false,
  );
}

/// Abstract interface for PIN authentication service
/// Implementation must handle secure hashing, storage, and validation
abstract class IPinService {
  /// Current PIN requirements configuration
  PinRequirements get requirements;
  
  /// Check if a PIN is currently set
  Future<bool> isPinSet();
  
  /// Validate PIN format according to requirements
  /// Throws PinValidationException if invalid
  void validatePin(String pin);
  
  /// Set a new PIN (first time setup or change)
  /// Returns the generated PinHash for storage
  Future<PinHash> setPin(String pin);
  
  /// Authenticate using PIN
  /// Handles lockout logic and attempt tracking
  Future<PinAuthResult> authenticate(String pin);
  
  /// Change existing PIN (requires current PIN verification)
  /// Returns new PinHash for storage
  Future<PinHash> changePin(String currentPin, String newPin);
  
  /// Force PIN reset (admin operation, clears attempt history)
  /// Returns new PinHash for storage
  Future<PinHash> resetPin(String newPin);
  
  /// Check if PIN hash needs security upgrade
  Future<bool> needsUpgrade();
  
  /// Upgrade PIN hash to current security standards
  /// Requires PIN re-verification
  Future<PinHash> upgradeHash(String pin);
  
  /// Clear attempt history (admin operation)
  Future<void> clearAttemptHistory();
  
  /// Get authentication statistics
  Future<Map<String, dynamic>> getAuthenticationStats();

  /// Get current lockout status
  Future<Duration?> getLockoutRemaining();

  /// Run comprehensive diagnostics for troubleshooting
  /// Returns storage info, PIN status, and any detected issues
  Future<Map<String, dynamic>> runDiagnostics();

  /// Secure cleanup of sensitive data
  void dispose();
}

/// Implementation-specific interface for storage operations
abstract class IPinStorageRepository {
  /// Load stored PIN hash
  Future<PinHash?> loadPinHash();
  
  /// Save PIN hash securely
  Future<void> savePinHash(PinHash pinHash);
  
  /// Delete stored PIN hash
  Future<void> deletePinHash();
  
  /// Load authentication attempt history
  Future<AuthAttemptHistory> loadAttemptHistory();
  
  /// Save authentication attempt history
  Future<void> saveAttemptHistory(AuthAttemptHistory history);
  
  /// Clear all authentication data
  Future<void> clearAll();

  /// Check if storage is properly initialized and accessible
  Future<bool> isAvailable();

  /// Get storage statistics for diagnostics
  Future<Map<String, dynamic>> getStorageInfo();

  /// Run comprehensive diagnostics
  Future<Map<String, dynamic>> runDiagnostics();
}

/// Implementation-specific interface for cryptographic operations
abstract class IPinCryptoProvider {
  /// Generate cryptographically secure salt
  Uint8List generateSalt({int length = 32});
  
  /// Hash PIN using PBKDF2 with given parameters
  Future<Uint8List> hashPin({
    required String pin,
    required Uint8List salt,
    required int iterations,
  });
  
  /// Verify PIN against stored hash in constant time
  Future<bool> verifyPin({
    required String pin,
    required PinHash storedHash,
  });
  
  /// Get recommended iteration count for current device performance
  Future<int> getRecommendedIterations();
  
  /// Secure memory clearing (best effort)
  void secureClear(Uint8List data);
}