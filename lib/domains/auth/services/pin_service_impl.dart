/// PIN Service Implementation
/// 
/// Concrete implementation of IPinService providing secure PIN authentication
/// with PBKDF2 hashing, lockout protection, and attempt tracking.
library;

import 'dart:typed_data';
import 'pin_service.dart';
import '../models/pin_hash.dart';
import '../models/auth_attempt.dart';
import '../providers/pbkdf2_crypto_provider.dart';

/// Default implementation of PIN authentication service
/// Handles all PIN operations with security best practices
class PinServiceImpl implements IPinService {
  /// Storage repository for persisting PIN data
  final IPinStorageRepository _storageRepository;
  
  /// Crypto provider for PIN hashing operations
  final IPinCryptoProvider _cryptoProvider;
  
  /// Current PIN requirements configuration
  final PinRequirements _requirements;
  
  /// Cached attempt history for performance
  AuthAttemptHistory? _cachedAttemptHistory;
  
  /// Constructor with dependency injection
  PinServiceImpl({
    required IPinStorageRepository storageRepository,
    IPinCryptoProvider? cryptoProvider,
    PinRequirements requirements = PinRequirements.secure,
  }) : _storageRepository = storageRepository,
        _cryptoProvider = cryptoProvider ?? Pbkdf2CryptoProvider(),
        _requirements = requirements;
  
  @override
  PinRequirements get requirements => _requirements;
  
  @override
  Future<bool> isPinSet() async {
    try {
      print('[PinService] Checking if PIN is set...');
      PinHash? storedHash = await _storageRepository.loadPinHash();
      bool isSet = storedHash != null;
      print('[PinService] PIN is set: $isSet');
      return isSet;
    } catch (e, stackTrace) {
      // ERROR: This was silently returning false, masking real errors
      print('[PinService] ERROR checking if PIN is set: $e');
      print('[PinService] Stack trace: $stackTrace');
      // If we can't load, assume no PIN is set
      return false;
    }
  }
  
  @override
  void validatePin(String pin) {
    List<String> violations = [];
    
    // Check length requirements
    if (pin.length < _requirements.minLength) {
      violations.add('PIN must be at least ${_requirements.minLength} characters');
    }
    
    if (pin.length > _requirements.maxLength) {
      violations.add('PIN must be no more than ${_requirements.maxLength} characters');
    }
    
    // Check digits only requirement
    if (_requirements.requireDigitsOnly) {
      RegExp digitsOnly = RegExp(r'^\d+$');
      if (!digitsOnly.hasMatch(pin)) {
        violations.add('PIN must contain only digits');
      }
    }
    
    // Check for common patterns
    if (_requirements.preventCommonPatterns) {
      _validateCommonPatterns(pin, violations);
    }
    
    // Check for repeating digits
    if (_requirements.preventRepeatingDigits) {
      _validateRepeatingDigits(pin, violations);
    }
    
    // Check for sequential digits
    if (_requirements.preventSequentialDigits) {
      _validateSequentialDigits(pin, violations);
    }
    
    if (violations.isNotEmpty) {
      throw PinValidationException(
        message: 'PIN validation failed',
        violations: violations,
      );
    }
  }
  
  @override
  Future<PinHash> setPin(String pin) async {
    print('[PinService] Setting new PIN...');
    validatePin(pin);

    try {
      // Generate secure salt
      Uint8List salt = _cryptoProvider.generateSalt();
      print('[PinService] Salt generated (${salt.length} bytes)');

      // Get recommended iterations for this device
      int iterations = await _cryptoProvider.getRecommendedIterations();
      print('[PinService] Using $iterations PBKDF2 iterations');

      // Hash the PIN
      Uint8List hash = await _cryptoProvider.hashPin(
        pin: pin,
        salt: salt,
        iterations: iterations,
      );
      print('[PinService] PIN hashed successfully (${hash.length} bytes)');

      // Create PinHash object
      PinHash pinHash = PinHash.create(
        hash: hash,
        salt: salt,
        iterations: iterations,
      );

      // Store securely
      await _storageRepository.savePinHash(pinHash);
      print('[PinService] PIN hash stored securely');

      // Clear attempt history on new PIN
      await clearAttemptHistory();
      print('[PinService] Attempt history cleared');

      print('[PinService] PIN setup completed successfully');
      return pinHash;

    } catch (e, stackTrace) {
      if (e is PinValidationException) rethrow;
      print('[PinService] ERROR setting PIN: $e');
      print('[PinService] Stack trace: $stackTrace');
      throw Exception('Failed to set PIN: $e');
    }
  }
  
  @override
  Future<PinAuthResult> authenticate(String pin) async {
    print('[PinService] Authenticating PIN...');

    if (pin.isEmpty) {
      print('[PinService] Authentication failed: PIN is empty');
      return PinAuthResult.invalidInput('PIN cannot be empty');
    }

    DateTime startTime = DateTime.now();

    try {
      // Load attempt history
      print('[PinService] Loading attempt history...');
      AuthAttemptHistory attemptHistory = await _getAttemptHistory();
      
      // Check for active lockout
      Duration? lockoutRemaining = attemptHistory.remainingLockoutTime;
      if (lockoutRemaining != null) {
        await _recordAttempt(AuthAttempt.create(
          result: AuthResult.lockedOut,
          duration: DateTime.now().difference(startTime),
        ));
        
        return PinAuthResult.lockedOut(
          lockoutRemaining: lockoutRemaining,
        );
      }
      
      // Load stored PIN hash
      print('[PinService] Loading stored PIN hash...');
      PinHash? storedHash = await _storageRepository.loadPinHash();
      if (storedHash == null) {
        print('[PinService] Authentication failed: No PIN has been set');
        await _recordAttempt(AuthAttempt.create(
          result: AuthResult.failure,
          details: 'No PIN set',
          duration: DateTime.now().difference(startTime),
        ));

        return PinAuthResult.invalidInput('No PIN has been set');
      }

      print('[PinService] Stored PIN hash loaded, verifying...');

      // Verify PIN
      bool isValid = await _cryptoProvider.verifyPin(
        pin: pin,
        storedHash: storedHash,
      );

      Duration authDuration = DateTime.now().difference(startTime);

      if (isValid) {
        // Successful authentication
        print('[PinService] Authentication successful (${authDuration.inMilliseconds}ms)');
        await _recordAttempt(AuthAttempt.create(
          result: AuthResult.success,
          duration: authDuration,
        ));

        return PinAuthResult.success(
          requiresUpgrade: storedHash.needsUpgrade(),
        );

      } else {
        // Failed authentication
        print('[PinService] Authentication failed: Invalid PIN');
        await _recordAttempt(AuthAttempt.create(
          result: AuthResult.failure,
          duration: authDuration,
        ));
        
        // Reload attempt history to get updated counts
        attemptHistory = await _getAttemptHistory();
        
        // Check if next failure would trigger lockout
        if (attemptHistory.wouldTriggerLockout) {
          return PinAuthResult.failure(
            message: 'Invalid PIN. Next failed attempt will lock your account.',
            remainingAttempts: 1,
          );
        }
        
        int failedAttempts = attemptHistory.recentFailures.length;
        int remainingAttempts = 
            AuthAttemptHistory.maxFailedAttempts - failedAttempts;
        
        return PinAuthResult.failure(
          message: 'Invalid PIN',
          remainingAttempts: remainingAttempts,
        );
      }
      
    } catch (e) {
      // Record failure on any error
      await _recordAttempt(AuthAttempt.create(
        result: AuthResult.failure,
        details: 'Authentication error: $e',
        duration: DateTime.now().difference(startTime),
      ));
      
      return PinAuthResult.failure(
        message: 'Authentication failed due to system error',
      );
    }
  }
  
  @override
  Future<PinHash> changePin(String currentPin, String newPin) async {
    // Verify current PIN
    PinAuthResult authResult = await authenticate(currentPin);
    
    if (!authResult.success) {
      throw PinAuthenticationException(
        message: 'Current PIN verification failed',
        result: authResult.result,
        lockoutRemaining: authResult.lockoutRemaining,
      );
    }
    
    // Set new PIN
    return await setPin(newPin);
  }
  
  @override
  Future<PinHash> resetPin(String newPin) async {
    // Clear attempt history
    await clearAttemptHistory();
    
    // Set new PIN
    return await setPin(newPin);
  }
  
  @override
  Future<bool> needsUpgrade() async {
    try {
      PinHash? storedHash = await _storageRepository.loadPinHash();
      return storedHash?.needsUpgrade() ?? false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<PinHash> upgradeHash(String pin) async {
    // Verify current PIN first
    PinAuthResult authResult = await authenticate(pin);
    
    if (!authResult.success) {
      throw PinAuthenticationException(
        message: 'PIN verification failed for upgrade',
        result: authResult.result,
        lockoutRemaining: authResult.lockoutRemaining,
      );
    }
    
    // Generate new hash with current security parameters
    return await setPin(pin);
  }
  
  @override
  Future<void> clearAttemptHistory() async {
    try {
      AuthAttemptHistory emptyHistory = AuthAttemptHistory([]);
      await _storageRepository.saveAttemptHistory(emptyHistory);
      _cachedAttemptHistory = emptyHistory;
    } catch (e) {
      throw Exception('Failed to clear attempt history: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getAuthenticationStats() async {
    try {
      AuthAttemptHistory attemptHistory = await _getAttemptHistory();
      Map<String, dynamic> stats = attemptHistory.getStatistics();
      
      // Add additional useful information
      stats['isLockedOut'] = attemptHistory.isLockedOut;
      stats['lockoutRemaining'] = attemptHistory.remainingLockoutTime?.inSeconds;
      stats['recentFailureCount'] = attemptHistory.recentFailures.length;
      stats['wouldTriggerLockout'] = attemptHistory.wouldTriggerLockout;
      
      return stats;
    } catch (e) {
      return {
        'error': 'Failed to get authentication statistics: $e',
      };
    }
  }
  
  @override
  Future<Duration?> getLockoutRemaining() async {
    try {
      AuthAttemptHistory attemptHistory = await _getAttemptHistory();
      return attemptHistory.remainingLockoutTime;
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    // Clear any cached sensitive data
    _cachedAttemptHistory = null;

    // Note: Repository and crypto provider should handle their own cleanup
  }

  @override
  Future<Map<String, dynamic>> runDiagnostics() async {
    Map<String, dynamic> diagnostics = {
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'PinServiceImpl',
    };

    try {
      // Check storage availability
      diagnostics['storageAvailable'] = await _storageRepository.isAvailable();

      // Get storage info
      Map<String, dynamic> storageInfo = await _storageRepository.getStorageInfo();
      diagnostics['storage'] = storageInfo;

      // Check if PIN is set
      bool pinSet = await isPinSet();
      diagnostics['isPinSet'] = pinSet;

      // Get auth stats
      Map<String, dynamic> authStats = await getAuthenticationStats();
      diagnostics['authStats'] = authStats;

      // Get lockout status
      Duration? lockout = await getLockoutRemaining();
      diagnostics['lockoutRemaining'] = lockout?.inSeconds;

      // Run storage diagnostics
      Map<String, dynamic> storageDiagnostics = await _storageRepository.runDiagnostics();
      diagnostics['storageDiagnostics'] = storageDiagnostics;

      diagnostics['status'] = 'ok';
    } catch (e, stackTrace) {
      diagnostics['status'] = 'error';
      diagnostics['error'] = e.toString();
      diagnostics['stackTrace'] = stackTrace.toString();
    }

    return diagnostics;
  }

  /// Get attempt history with caching
  Future<AuthAttemptHistory> _getAttemptHistory() async {
    if (_cachedAttemptHistory == null) {
      _cachedAttemptHistory = await _storageRepository.loadAttemptHistory();
    }
    return _cachedAttemptHistory!;
  }
  
  /// Record authentication attempt and update cache
  Future<void> _recordAttempt(AuthAttempt attempt) async {
    try {
      AuthAttemptHistory attemptHistory = await _getAttemptHistory();
      attemptHistory.addAttempt(attempt);
      
      await _storageRepository.saveAttemptHistory(attemptHistory);
      _cachedAttemptHistory = attemptHistory;
    } catch (e) {
      // Don't fail authentication due to logging issues
      // but this should be logged for monitoring
    }
  }
  
  /// Validate against common PIN patterns
  void _validateCommonPatterns(String pin, List<String> violations) {
    // List of common weak PINs (including 4-digit ones)
    const List<String> commonPins = [
      // 4-digit common PINs
      '0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999',
      '1234', '4321', '1212', '2580', '0852', '1010', '2468', '1357',
      // 5-digit common PINs  
      '12345', '54321', '11111', '00000',
      // 6-digit common PINs
      '123456', '654321', '111111', '000000', '123123',
      '121212', '101010', '555555', '987654', '246810',
      '135791', '112233',
    ];
    
    if (commonPins.contains(pin)) {
      violations.add('PIN is too common and easily guessed');
    }
    
    // Check for birthday patterns (DDMM, MMDD, MMYY, YYYY)
    if (pin.length == 4) {
      // For 4-digit PINs, check for year patterns (1900-2099) and simple date patterns
      RegExp yearPattern = RegExp(r'^(19|20)\d{2}$');
      RegExp datePattern = RegExp(r'^(0[1-9]|[12][0-9]|3[01])(0[1-9]|1[0-2])$|^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$');
      if (yearPattern.hasMatch(pin) || datePattern.hasMatch(pin)) {
        violations.add('PIN appears to be a date pattern');
      }
    } else if (pin.length >= 6) {
      // For longer PINs, check for more complex date patterns
      RegExp birthdayPattern = RegExp(r'^(0[1-9]|[12][0-9]|3[01])(0[1-9]|1[0-2])\d{2}$|^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])\d{2}$');
      if (birthdayPattern.hasMatch(pin)) {
        violations.add('PIN appears to be a date pattern');
      }
    }
  }
  
  /// Validate against repeating digits
  void _validateRepeatingDigits(String pin, List<String> violations) {
    // Check for all same digits
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      violations.add('PIN cannot contain only repeating digits');
    }
    
    // Check for excessive repetition (more than 2 consecutive same digits)
    if (RegExp(r'(\d)\1{2,}').hasMatch(pin)) {
      violations.add('PIN cannot contain more than 2 consecutive identical digits');
    }
  }
  
  /// Validate against sequential digits
  void _validateSequentialDigits(String pin, List<String> violations) {
    if (pin.length < 3) return; // Too short for meaningful sequence check
    
    // Check for ascending sequences
    bool hasAscending = _hasSequence(pin, ascending: true);
    bool hasDescending = _hasSequence(pin, ascending: false);
    
    if (hasAscending || hasDescending) {
      violations.add('PIN cannot contain sequential digits');
    }
  }
  
  /// Check if PIN contains sequential digits
  bool _hasSequence(String pin, {required bool ascending}) {
    for (int i = 0; i < pin.length - 2; i++) {
      int first = int.parse(pin[i]);
      int second = int.parse(pin[i + 1]);
      int third = int.parse(pin[i + 2]);
      
      if (ascending) {
        if (second == first + 1 && third == second + 1) {
          return true;
        }
      } else {
        if (second == first - 1 && third == second - 1) {
          return true;
        }
      }
    }
    
    return false;
  }
}