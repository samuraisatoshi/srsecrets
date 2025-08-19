/// Authentication Attempt Model for Lockout Management
/// 
/// Tracks authentication attempts to implement security lockout mechanisms.
/// Immutable value object following DDD principles.
library;

/// Result of an authentication attempt
enum AuthResult {
  success,
  failure,
  lockedOut,
  invalidInput,
}

/// Represents a single authentication attempt
/// Immutable value object for audit trail and security analysis
class AuthAttempt {
  /// Timestamp of the attempt
  final DateTime timestamp;
  
  /// Result of the authentication attempt
  final AuthResult result;
  
  /// Source IP or identifier (empty for air-gapped systems)
  final String source;
  
  /// Optional additional details about the attempt
  final String? details;
  
  /// Duration taken for the attempt (for timing analysis)
  final Duration duration;
  
  /// Private constructor for validation
  const AuthAttempt._({
    required this.timestamp,
    required this.result,
    required this.source,
    required this.duration,
    this.details,
  });
  
  /// Create a new authentication attempt
  factory AuthAttempt.create({
    required AuthResult result,
    String source = 'local',
    String? details,
    Duration? duration,
    DateTime? timestamp,
  }) {
    return AuthAttempt._(
      timestamp: timestamp ?? DateTime.now(),
      result: result,
      source: source,
      details: details,
      duration: duration ?? Duration.zero,
    );
  }
  
  /// Create from storage format
  factory AuthAttempt.fromMap(Map<String, dynamic> map) {
    return AuthAttempt.create(
      timestamp: DateTime.parse(map['timestamp'] as String),
      result: AuthResult.values.firstWhere(
        (e) => e.toString() == map['result'],
      ),
      source: map['source'] as String,
      details: map['details'] as String?,
      duration: Duration(microseconds: map['durationMicros'] as int),
    );
  }
  
  /// Convert to storage format
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'result': result.toString(),
      'source': source,
      'details': details,
      'durationMicros': duration.inMicroseconds,
    };
  }
  
  /// Check if this attempt was successful
  bool get isSuccess => result == AuthResult.success;
  
  /// Check if this attempt was a failure
  bool get isFailure => result == AuthResult.failure;
  
  /// Check if this attempt resulted in lockout
  bool get isLockedOut => result == AuthResult.lockedOut;
  
  /// Check if attempt is within specified time window
  bool isWithinWindow(Duration window) {
    return DateTime.now().difference(timestamp) <= window;
  }
  
  /// Check if attempt is considered suspicious (very fast or very slow)
  bool isSuspicious() {
    const Duration minTime = Duration(milliseconds: 100);
    const Duration maxTime = Duration(seconds: 30);
    
    return duration < minTime || duration > maxTime;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthAttempt &&
           timestamp == other.timestamp &&
           result == other.result &&
           source == other.source &&
           details == other.details &&
           duration == other.duration;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      result,
      source,
      details,
      duration,
    );
  }
  
  @override
  String toString() {
    return 'AuthAttempt(timestamp: $timestamp, result: $result, '
           'source: $source, duration: ${duration.inMilliseconds}ms)';
  }
}

/// Manages authentication attempt history and lockout logic
class AuthAttemptHistory {
  /// Maximum failed attempts before lockout
  static const int maxFailedAttempts = 5;
  
  /// Lockout duration after max failed attempts
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  /// Time window for counting failed attempts
  static const Duration failureWindow = Duration(minutes: 30);
  
  /// List of authentication attempts (most recent first)
  final List<AuthAttempt> _attempts;
  
  /// Create new attempt history
  AuthAttemptHistory(List<AuthAttempt>? attempts) 
    : _attempts = List<AuthAttempt>.from(attempts ?? []);
  
  /// Create from storage format
  factory AuthAttemptHistory.fromMap(Map<String, dynamic> map) {
    List<dynamic> attemptsJson = map['attempts'] as List<dynamic>;
    List<AuthAttempt> attempts = attemptsJson
        .map((json) => AuthAttempt.fromMap(json as Map<String, dynamic>))
        .toList();
    return AuthAttemptHistory(attempts);
  }
  
  /// Convert to storage format
  Map<String, dynamic> toMap() {
    return {
      'attempts': _attempts.map((attempt) => attempt.toMap()).toList(),
    };
  }
  
  /// Get all attempts (read-only)
  List<AuthAttempt> get attempts => List.unmodifiable(_attempts);
  
  /// Get recent failed attempts within the failure window
  List<AuthAttempt> get recentFailures {
    DateTime cutoff = DateTime.now().subtract(failureWindow);
    return _attempts
        .where((attempt) => 
            attempt.isFailure && attempt.timestamp.isAfter(cutoff))
        .toList();
  }
  
  /// Get the most recent lockout attempt if still active
  AuthAttempt? get activeLockout {
    DateTime cutoff = DateTime.now().subtract(lockoutDuration);
    
    for (AuthAttempt attempt in _attempts) {
      if (attempt.isLockedOut && attempt.timestamp.isAfter(cutoff)) {
        return attempt;
      }
      // Stop at first non-lockout attempt (chronologically ordered)
      if (!attempt.isLockedOut) break;
    }
    
    return null;
  }
  
  /// Check if account is currently locked out
  bool get isLockedOut => activeLockout != null;
  
  /// Get remaining lockout time
  Duration? get remainingLockoutTime {
    AuthAttempt? lockout = activeLockout;
    if (lockout == null) return null;
    
    DateTime unlockTime = lockout.timestamp.add(lockoutDuration);
    Duration remaining = unlockTime.difference(DateTime.now());
    
    return remaining.isNegative ? null : remaining;
  }
  
  /// Check if next failed attempt would trigger lockout
  bool get wouldTriggerLockout {
    return recentFailures.length >= (maxFailedAttempts - 1);
  }
  
  /// Add new authentication attempt
  void addAttempt(AuthAttempt attempt) {
    _attempts.insert(0, attempt); // Add to beginning (most recent first)
    _cleanupOldAttempts();
  }
  
  /// Remove attempts older than retention period
  void _cleanupOldAttempts() {
    const Duration retentionPeriod = Duration(days: 30);
    DateTime cutoff = DateTime.now().subtract(retentionPeriod);
    
    _attempts.removeWhere((attempt) => attempt.timestamp.isBefore(cutoff));
    
    // Keep maximum of 1000 attempts for memory management
    const int maxAttempts = 1000;
    if (_attempts.length > maxAttempts) {
      _attempts.removeRange(maxAttempts, _attempts.length);
    }
  }
  
  /// Get statistics about authentication attempts
  Map<String, dynamic> getStatistics() {
    if (_attempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'successfulAttempts': 0,
        'failedAttempts': 0,
        'lockoutAttempts': 0,
        'averageResponseTime': 0,
        'lastSuccessfulAuth': null,
      };
    }
    
    int successful = 0;
    int failed = 0;
    int lockedOut = 0;
    int totalDuration = 0;
    AuthAttempt? lastSuccess;
    
    for (AuthAttempt attempt in _attempts) {
      switch (attempt.result) {
        case AuthResult.success:
          successful++;
          lastSuccess ??= attempt; // Most recent success
          break;
        case AuthResult.failure:
          failed++;
          break;
        case AuthResult.lockedOut:
          lockedOut++;
          break;
        case AuthResult.invalidInput:
          // Count as failed for statistics
          failed++;
          break;
      }
      
      totalDuration += attempt.duration.inMicroseconds;
    }
    
    return {
      'totalAttempts': _attempts.length,
      'successfulAttempts': successful,
      'failedAttempts': failed,
      'lockoutAttempts': lockedOut,
      'averageResponseTime': totalDuration ~/ _attempts.length,
      'lastSuccessfulAuth': lastSuccess?.timestamp.toIso8601String(),
    };
  }
  
  /// Clear all attempt history (for testing or reset)
  void clear() {
    _attempts.clear();
  }
}