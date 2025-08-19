/// Unit tests for AuthAttempt and AuthAttemptHistory models
/// 
/// Tests authentication attempt tracking and lockout logic
/// with comprehensive security validation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/auth/models/auth_attempt.dart';

void main() {
  group('AuthAttempt', () {
    test('should create AuthAttempt with default values', () {
      final attempt = AuthAttempt.create(
        result: AuthResult.success,
      );
      
      expect(attempt.result, equals(AuthResult.success));
      expect(attempt.source, equals('local'));
      expect(attempt.duration, equals(Duration.zero));
      expect(attempt.timestamp, isNotNull);
      expect(attempt.details, isNull);
    });
    
    test('should create AuthAttempt with custom values', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final duration = Duration(milliseconds: 150);
      
      final attempt = AuthAttempt.create(
        result: AuthResult.failure,
        source: 'test',
        details: 'Test failure',
        duration: duration,
        timestamp: timestamp,
      );
      
      expect(attempt.result, equals(AuthResult.failure));
      expect(attempt.source, equals('test'));
      expect(attempt.details, equals('Test failure'));
      expect(attempt.duration, equals(duration));
      expect(attempt.timestamp, equals(timestamp));
    });
    
    group('fromMap/toMap', () {
      test('should serialize and deserialize correctly', () {
        final original = AuthAttempt.create(
          result: AuthResult.failure,
          source: 'mobile',
          details: 'Invalid PIN',
          duration: Duration(milliseconds: 200),
          timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        );
        
        final map = original.toMap();
        final restored = AuthAttempt.fromMap(map);
        
        expect(restored.result, equals(original.result));
        expect(restored.source, equals(original.source));
        expect(restored.details, equals(original.details));
        expect(restored.duration, equals(original.duration));
        expect(restored.timestamp, equals(original.timestamp));
      });
    });
    
    group('convenience properties', () {
      test('isSuccess should return correct value', () {
        final successAttempt = AuthAttempt.create(result: AuthResult.success);
        final failureAttempt = AuthAttempt.create(result: AuthResult.failure);
        
        expect(successAttempt.isSuccess, isTrue);
        expect(failureAttempt.isSuccess, isFalse);
      });
      
      test('isFailure should return correct value', () {
        final successAttempt = AuthAttempt.create(result: AuthResult.success);
        final failureAttempt = AuthAttempt.create(result: AuthResult.failure);
        
        expect(successAttempt.isFailure, isFalse);
        expect(failureAttempt.isFailure, isTrue);
      });
      
      test('isLockedOut should return correct value', () {
        final lockoutAttempt = AuthAttempt.create(result: AuthResult.lockedOut);
        final successAttempt = AuthAttempt.create(result: AuthResult.success);
        
        expect(lockoutAttempt.isLockedOut, isTrue);
        expect(successAttempt.isLockedOut, isFalse);
      });
    });
    
    group('isWithinWindow', () {
      test('should return true for recent attempt', () {
        final recentAttempt = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        );
        
        expect(recentAttempt.isWithinWindow(Duration(minutes: 10)), isTrue);
      });
      
      test('should return false for old attempt', () {
        final oldAttempt = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        );
        
        expect(oldAttempt.isWithinWindow(Duration(minutes: 10)), isFalse);
      });
    });
    
    group('isSuspicious', () {
      test('should return true for very fast attempt', () {
        final fastAttempt = AuthAttempt.create(
          result: AuthResult.success,
          duration: Duration(milliseconds: 50),
        );
        
        expect(fastAttempt.isSuspicious(), isTrue);
      });
      
      test('should return true for very slow attempt', () {
        final slowAttempt = AuthAttempt.create(
          result: AuthResult.success,
          duration: Duration(seconds: 45),
        );
        
        expect(slowAttempt.isSuspicious(), isTrue);
      });
      
      test('should return false for normal timing', () {
        final normalAttempt = AuthAttempt.create(
          result: AuthResult.success,
          duration: Duration(milliseconds: 500),
        );
        
        expect(normalAttempt.isSuspicious(), isFalse);
      });
    });
  });
  
  group('AuthAttemptHistory', () {
    late List<AuthAttempt> testAttempts;
    late DateTime baseTime;
    
    setUp(() {
      baseTime = DateTime.now().subtract(Duration(minutes: 60));
      testAttempts = [
        AuthAttempt.create(
          result: AuthResult.success,
          timestamp: baseTime,
        ),
        AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: baseTime.add(Duration(minutes: 10)),
        ),
        AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: baseTime.add(Duration(minutes: 20)),
        ),
      ];
    });
    
    test('should create empty history', () {
      final history = AuthAttemptHistory(null);
      
      expect(history.attempts, isEmpty);
      expect(history.isLockedOut, isFalse);
    });
    
    test('should create history with attempts', () {
      final history = AuthAttemptHistory(testAttempts);
      
      expect(history.attempts, hasLength(3));
      expect(history.attempts, equals(testAttempts));
    });
    
    group('fromMap/toMap', () {
      test('should serialize and deserialize correctly', () {
        final original = AuthAttemptHistory(testAttempts);
        
        final map = original.toMap();
        final restored = AuthAttemptHistory.fromMap(map);
        
        expect(restored.attempts, hasLength(original.attempts.length));
        for (int i = 0; i < original.attempts.length; i++) {
          expect(restored.attempts[i].result, equals(original.attempts[i].result));
          expect(restored.attempts[i].timestamp, equals(original.attempts[i].timestamp));
        }
      });
    });
    
    group('recentFailures', () {
      test('should return recent failures within window', () {
        final now = DateTime.now();
        final recentFailure = AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: now.subtract(Duration(minutes: 10)),
        );
        final oldFailure = AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: now.subtract(Duration(minutes: 40)),
        );
        
        final history = AuthAttemptHistory([recentFailure, oldFailure]);
        final recentFailures = history.recentFailures;
        
        expect(recentFailures, hasLength(1));
        expect(recentFailures.first.timestamp, equals(recentFailure.timestamp));
      });
      
      test('should not include success attempts', () {
        final now = DateTime.now();
        final recentSuccess = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: now.subtract(Duration(minutes: 10)),
        );
        final recentFailure = AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: now.subtract(Duration(minutes: 5)),
        );
        
        final history = AuthAttemptHistory([recentSuccess, recentFailure]);
        final recentFailures = history.recentFailures;
        
        expect(recentFailures, hasLength(1));
        expect(recentFailures.first.result, equals(AuthResult.failure));
      });
    });
    
    group('lockout logic', () {
      test('should detect active lockout', () {
        final now = DateTime.now();
        final lockoutAttempt = AuthAttempt.create(
          result: AuthResult.lockedOut,
          timestamp: now.subtract(Duration(minutes: 5)),
        );
        
        final history = AuthAttemptHistory([lockoutAttempt]);
        
        expect(history.isLockedOut, isTrue);
        expect(history.activeLockout, isNotNull);
        expect(history.remainingLockoutTime, isNotNull);
      });
      
      test('should not detect expired lockout', () {
        final now = DateTime.now();
        final expiredLockout = AuthAttempt.create(
          result: AuthResult.lockedOut,
          timestamp: now.subtract(Duration(minutes: 20)), // Beyond 15-minute lockout
        );
        
        final history = AuthAttemptHistory([expiredLockout]);
        
        expect(history.isLockedOut, isFalse);
        expect(history.activeLockout, isNull);
        expect(history.remainingLockoutTime, isNull);
      });
      
      test('should calculate remaining lockout time correctly', () {
        final now = DateTime.now();
        final lockoutAttempt = AuthAttempt.create(
          result: AuthResult.lockedOut,
          timestamp: now.subtract(Duration(minutes: 5)),
        );
        
        final history = AuthAttemptHistory([lockoutAttempt]);
        final remaining = history.remainingLockoutTime;
        
        expect(remaining, isNotNull);
        expect(remaining!.inMinutes, closeTo(10, 1)); // ~10 minutes remaining
      });
      
      test('should detect when next failure would trigger lockout', () {
        final now = DateTime.now();
        final failures = List.generate(4, (index) => AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: now.subtract(Duration(minutes: index * 2)),
        ));
        
        final history = AuthAttemptHistory(failures);
        
        expect(history.wouldTriggerLockout, isTrue);
      });
      
      test('should not trigger lockout with fewer failures', () {
        final now = DateTime.now();
        final failures = List.generate(3, (index) => AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: now.subtract(Duration(minutes: index * 2)),
        ));
        
        final history = AuthAttemptHistory(failures);
        
        expect(history.wouldTriggerLockout, isFalse);
      });
    });
    
    group('addAttempt', () {
      test('should add attempt to beginning of list', () {
        final history = AuthAttemptHistory([]);
        final newAttempt = AuthAttempt.create(result: AuthResult.success);
        
        history.addAttempt(newAttempt);
        
        expect(history.attempts, hasLength(1));
        expect(history.attempts.first, equals(newAttempt));
      });
      
      test('should maintain chronological order (newest first)', () {
        final history = AuthAttemptHistory([]);
        final attempt1 = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: DateTime.now().subtract(Duration(minutes: 10)),
        );
        final attempt2 = AuthAttempt.create(
          result: AuthResult.failure,
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        );
        
        history.addAttempt(attempt1);
        history.addAttempt(attempt2);
        
        expect(history.attempts.first, equals(attempt2)); // Most recent first
        expect(history.attempts.last, equals(attempt1));
      });
    });
    
    group('cleanup', () {
      test('should remove old attempts', () {
        final now = DateTime.now();
        final oldAttempt = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: now.subtract(Duration(days: 35)),
        );
        final recentAttempt = AuthAttempt.create(
          result: AuthResult.success,
          timestamp: now.subtract(Duration(days: 5)),
        );
        
        final history = AuthAttemptHistory([oldAttempt, recentAttempt]);
        history.addAttempt(AuthAttempt.create(result: AuthResult.success)); // Triggers cleanup
        
        // Old attempt should be removed, recent ones kept
        expect(history.attempts.any((a) => a.timestamp == oldAttempt.timestamp), isFalse);
        expect(history.attempts.any((a) => a.timestamp == recentAttempt.timestamp), isTrue);
      });
    });
    
    group('getStatistics', () {
      test('should return correct statistics for empty history', () {
        final history = AuthAttemptHistory([]);
        final stats = history.getStatistics();
        
        expect(stats['totalAttempts'], equals(0));
        expect(stats['successfulAttempts'], equals(0));
        expect(stats['failedAttempts'], equals(0));
        expect(stats['lockoutAttempts'], equals(0));
        expect(stats['averageResponseTime'], equals(0));
        expect(stats['lastSuccessfulAuth'], isNull);
      });
      
      test('should return correct statistics for mixed attempts', () {
        final attempts = [
          AuthAttempt.create(
            result: AuthResult.success,
            duration: Duration(milliseconds: 200),
            timestamp: DateTime(2024, 1, 1, 12, 0, 0),
          ),
          AuthAttempt.create(
            result: AuthResult.failure,
            duration: Duration(milliseconds: 300),
          ),
          AuthAttempt.create(
            result: AuthResult.lockedOut,
            duration: Duration(milliseconds: 100),
          ),
          AuthAttempt.create(
            result: AuthResult.invalidInput,
            duration: Duration(milliseconds: 50),
          ),
        ];
        
        final history = AuthAttemptHistory(attempts);
        final stats = history.getStatistics();
        
        expect(stats['totalAttempts'], equals(4));
        expect(stats['successfulAttempts'], equals(1));
        expect(stats['failedAttempts'], equals(2)); // failure + invalidInput
        expect(stats['lockoutAttempts'], equals(1));
        expect(stats['averageResponseTime'], equals(162500)); // Average in microseconds
        expect(stats['lastSuccessfulAuth'], isNotNull);
      });
    });
    
    group('clear', () {
      test('should remove all attempts', () {
        final history = AuthAttemptHistory(testAttempts);
        
        expect(history.attempts, isNotEmpty);
        
        history.clear();
        
        expect(history.attempts, isEmpty);
      });
    });
  });
}