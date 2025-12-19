import 'package:flutter/foundation.dart';

import '../../domains/auth/services/pin_service.dart';
import '../../domains/auth/services/pin_service_impl.dart';
import '../../domains/auth/services/pin_validator.dart';
import '../../domains/auth/providers/pbkdf2_crypto_provider.dart';
import '../../infrastructure/persistence/secure_storage_repository.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final IPinService _pinService;

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isPinSet = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  bool _isLocked = false;
  Duration _lockoutDuration = Duration.zero;

  /// Constructor with dependency injection
  /// Falls back to default implementations if not provided
  AuthProvider({IPinService? pinService})
      : _pinService = pinService ??
            PinServiceImpl(
              storageRepository: SecureStorageRepository(),
              cryptoProvider: Pbkdf2CryptoProvider(),
              pinValidator: const PinValidator(),
            );

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isPinSet => _isPinSet;
  String? get errorMessage => _errorMessage;
  int get failedAttempts => _failedAttempts;
  bool get isLocked => _isLocked;
  Duration get lockoutDuration => _lockoutDuration;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if PIN is already set and authentication status
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _isPinSet = await _pinService.isPinSet();
      _isAuthenticated = false; // Always require authentication on app start
      
      // For now, assume no failed attempts on app start
      // In a real implementation, you'd store attempt history
      _failedAttempts = 0;
      _isLocked = false;
      _lockoutDuration = Duration.zero;
    } catch (e) {
      _setError('Failed to check authentication status: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set up a new PIN
  Future<bool> setupPin(String pin) async {
    _setLoading(true);
    _clearError();

    try {
      await _pinService.setPin(pin);
      _isPinSet = true;
      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to setup PIN: $e');
      _setLoading(false);
      return false;
    }
  }

  // Authenticate with PIN
  Future<bool> authenticate(String pin) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _pinService.authenticate(pin);
      
      if (result.success) {
        _isAuthenticated = true;
        _failedAttempts = 0;
        _isLocked = false;
        _lockoutDuration = Duration.zero;
        _setLoading(false);
        return true;
      } else {
        _failedAttempts = result.remainingAttempts ?? 0;
        _isLocked = result.lockoutRemaining != null;
        if (_isLocked) {
          _lockoutDuration = result.lockoutRemaining ?? Duration.zero;
          _setError('Too many failed attempts. Please wait ${_formatDuration(_lockoutDuration)}');
        } else {
          _setError(result.message ?? 'Invalid PIN');
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Authentication failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  void logout() {
    _isAuthenticated = false;
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  // Validate PIN format
  bool isValidPin(String pin) {
    // PIN must be 4-8 digits
    if (pin.length < 4 || pin.length > 8) {
      return false;
    }

    // Must contain only digits
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return false;
    }

    // Check for common weak patterns (handled by PinService)
    return true;
  }

  /// Run comprehensive diagnostics for troubleshooting PIN issues
  /// Use this when users report being stuck on PIN screen
  Future<Map<String, dynamic>> runDiagnostics() async {
    try {
      return await _pinService.runDiagnostics();
    } catch (e) {
      return {
        'status': 'error',
        'error': 'Failed to run diagnostics: $e',
      };
    }
  }
}