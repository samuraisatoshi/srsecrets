/// Unit tests for PBKDF2 Cryptographic Provider
/// 
/// Tests secure PIN hashing, salt generation, and verification
/// with comprehensive security validation.
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/auth/providers/pbkdf2_crypto_provider.dart';
import 'package:srsecrets/domains/auth/models/pin_hash.dart';

void main() {
  group('Pbkdf2CryptoProvider', () {
    late Pbkdf2CryptoProvider provider;
    
    setUp(() {
      provider = Pbkdf2CryptoProvider();
    });
    
    group('generateSalt', () {
      test('should generate salt with default length', () {
        final salt = provider.generateSalt();
        
        expect(salt, isA<Uint8List>());
        expect(salt.length, equals(32)); // Default salt length
      });
      
      test('should generate salt with custom length', () {
        final salt = provider.generateSalt(length: 64);
        
        expect(salt.length, equals(64));
      });
      
      test('should generate different salts on subsequent calls', () {
        final salt1 = provider.generateSalt();
        final salt2 = provider.generateSalt();
        
        expect(salt1, isNot(equals(salt2)));
      });
      
      test('should throw error for invalid length', () {
        expect(() => provider.generateSalt(length: 0), throwsArgumentError);
        expect(() => provider.generateSalt(length: -1), throwsArgumentError);
        expect(() => provider.generateSalt(length: 8), throwsArgumentError); // Too short
      });
      
      test('should generate cryptographically random salts', () {
        // Generate multiple salts and check for randomness
        final salts = List.generate(100, (_) => provider.generateSalt(length: 16));
        
        // Check that all salts are unique (highly probable with good randomness)
        final uniqueSalts = salts.toSet();
        expect(uniqueSalts.length, equals(100));
        
        // Check entropy - no salt should be all zeros or all same value
        for (final salt in salts) {
          expect(salt.every((byte) => byte == 0), isFalse);
          expect(salt.every((byte) => byte == salt[0]), isFalse);
        }
      });
    });
    
    group('hashPin', () {
      test('should hash PIN with given parameters', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: iterations,
        );
        
        expect(hash, isA<Uint8List>());
        expect(hash.length, equals(32)); // SHA-256 output length
        expect(hash.every((byte) => byte == 0), isFalse); // Not all zeros
      });
      
      test('should produce different hashes for different PINs', () async {
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash1 = await provider.hashPin(
          pin: 'pin123',
          salt: salt,
          iterations: iterations,
        );
        
        final hash2 = await provider.hashPin(
          pin: 'pin456',
          salt: salt,
          iterations: iterations,
        );
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('should produce different hashes for different salts', () async {
        const pin = 'test123';
        const iterations = 100000;
        
        final salt1 = provider.generateSalt();
        final salt2 = provider.generateSalt();
        
        final hash1 = await provider.hashPin(
          pin: pin,
          salt: salt1,
          iterations: iterations,
        );
        
        final hash2 = await provider.hashPin(
          pin: pin,
          salt: salt2,
          iterations: iterations,
        );
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('should produce different hashes for different iterations', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        
        final hash1 = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: 100000,
        );
        
        final hash2 = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: 200000,
        );
        
        expect(hash1, isNot(equals(hash2)));
      });
      
      test('should produce identical hashes for identical inputs', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash1 = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: iterations,
        );
        
        final hash2 = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: iterations,
        );
        
        expect(hash1, equals(hash2));
      });
      
      test('should throw error for invalid parameters', () async {
        final salt = provider.generateSalt();
        
        // Empty PIN
        expect(
          () => provider.hashPin(
            pin: '',
            salt: salt,
            iterations: 100000,
          ),
          throwsArgumentError,
        );
        
        // Empty salt
        expect(
          () => provider.hashPin(
            pin: 'test123',
            salt: Uint8List(0),
            iterations: 100000,
          ),
          throwsArgumentError,
        );
        
        // Too few iterations
        expect(
          () => provider.hashPin(
            pin: 'test123',
            salt: salt,
            iterations: 50000,
          ),
          throwsArgumentError,
        );
      });
    });
    
    group('verifyPin', () {
      test('should verify correct PIN', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValid = await provider.verifyPin(
          pin: pin,
          storedHash: pinHash,
        );
        
        expect(isValid, isTrue);
      });
      
      test('should reject incorrect PIN', () async {
        const correctPin = 'test123';
        const incorrectPin = 'test456';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: correctPin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValid = await provider.verifyPin(
          pin: incorrectPin,
          storedHash: pinHash,
        );
        
        expect(isValid, isFalse);
      });
      
      test('should reject empty PIN', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValid = await provider.verifyPin(
          pin: '',
          storedHash: pinHash,
        );
        
        expect(isValid, isFalse);
      });
      
      test('should handle verification errors gracefully', () async {
        const pin = 'test123';
        
        // Create invalid PinHash that will cause verification error
        final invalidPinHash = PinHash.create(
          hash: Uint8List.fromList([]), // Empty hash will cause error
          salt: provider.generateSalt(),
          iterations: 100000,
        );
        
        final isValid = await provider.verifyPin(
          pin: pin,
          storedHash: invalidPinHash,
        );
        
        // Should return false on any error
        expect(isValid, isFalse);
      });
    });
    
    group('getRecommendedIterations', () {
      test('should return reasonable iteration count', () async {
        final iterations = await provider.getRecommendedIterations();
        
        expect(iterations, greaterThanOrEqualTo(100000));
        expect(iterations, lessThanOrEqualTo(1000000));
      });
    });
    
    group('secureClear', () {
      test('should clear sensitive data array', () {
        final sensitiveData = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        provider.secureClear(sensitiveData);
        
        expect(sensitiveData.every((byte) => byte == 0), isTrue);
      });
      
      test('should handle empty array', () {
        final emptyData = Uint8List(0);
        
        expect(() => provider.secureClear(emptyData), returnsNormally);
      });
    });
    
    group('benchmarkPerformance', () {
      test('should return performance metrics', () async {
        final benchmark = await provider.benchmarkPerformance();
        
        expect(benchmark, containsPair('testIterations', 10000));
        expect(benchmark['elapsedMicroseconds'], greaterThan(0));
        expect(benchmark['microsecondsPerIteration'], greaterThan(0));
        expect(benchmark['recommendedIterations'], greaterThanOrEqualTo(100000));
        expect(benchmark['targetMilliseconds'], equals(500));
      });
      
      test('should provide consistent results', () async {
        final benchmark1 = await provider.benchmarkPerformance();
        final benchmark2 = await provider.benchmarkPerformance();
        
        // Results should be in the same ballpark
        final ratio = benchmark1['elapsedMicroseconds'] / benchmark2['elapsedMicroseconds'];
        expect(ratio, greaterThan(0.5));
        expect(ratio, lessThan(2.0));
      });
    });
    
    group('security properties', () {
      test('should be resistant to timing attacks', () async {
        const correctPin = 'correct123';
        const incorrectPin = 'wrong456';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: correctPin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        // Measure timing for correct PIN
        final stopwatch1 = Stopwatch()..start();
        await provider.verifyPin(pin: correctPin, storedHash: pinHash);
        stopwatch1.stop();
        
        // Measure timing for incorrect PIN
        final stopwatch2 = Stopwatch()..start();
        await provider.verifyPin(pin: incorrectPin, storedHash: pinHash);
        stopwatch2.stop();
        
        // Timing difference should be minimal (within 10ms)
        final timingDifference = (stopwatch1.elapsedMilliseconds - stopwatch2.elapsedMilliseconds).abs();
        expect(timingDifference, lessThan(10));
      });
      
      test('should handle Unicode PINs correctly', () async {
        const unicodePin = 'тест123'; // Cyrillic characters
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: unicodePin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValid = await provider.verifyPin(
          pin: unicodePin,
          storedHash: pinHash,
        );
        
        expect(isValid, isTrue);
      });
      
      test('should be case-sensitive', () async {
        const lowerPin = 'test123';
        const upperPin = 'TEST123';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: lowerPin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValidLower = await provider.verifyPin(
          pin: lowerPin,
          storedHash: pinHash,
        );
        
        final isValidUpper = await provider.verifyPin(
          pin: upperPin,
          storedHash: pinHash,
        );
        
        expect(isValidLower, isTrue);
        expect(isValidUpper, isFalse);
      });
    });
    
    group('edge cases', () {
      test('should handle very long PINs', () async {
        final longPin = 'a' * 1000; // 1000 character PIN
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: longPin,
          salt: salt,
          iterations: iterations,
        );
        
        expect(hash.length, equals(32));
      });
      
      test('should handle special characters in PIN', () async {
        const specialPin = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
        final salt = provider.generateSalt();
        const iterations = 100000;
        
        final hash = await provider.hashPin(
          pin: specialPin,
          salt: salt,
          iterations: iterations,
        );
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: iterations,
        );
        
        final isValid = await provider.verifyPin(
          pin: specialPin,
          storedHash: pinHash,
        );
        
        expect(isValid, isTrue);
      });
      
      test('should handle maximum iteration count', () async {
        const pin = 'test123';
        final salt = provider.generateSalt();
        const maxIterations = 1000000; // 1M iterations
        
        final hash = await provider.hashPin(
          pin: pin,
          salt: salt,
          iterations: maxIterations,
        );
        
        expect(hash.length, equals(32));
      });
    });
  });
}