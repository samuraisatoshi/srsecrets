/// Unit tests for PinHash model
/// 
/// Tests the immutable value object representing hashed PINs
/// with comprehensive validation and security checks.
library;

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/auth/models/pin_hash.dart';

void main() {
  group('PinHash', () {
    late Uint8List testHash;
    late Uint8List testSalt;
    late DateTime testCreatedAt;
    
    setUp(() {
      testHash = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      testSalt = Uint8List.fromList([9, 10, 11, 12, 13, 14, 15, 16]);
      testCreatedAt = DateTime(2024, 1, 1, 12, 0, 0);
    });
    
    group('create', () {
      test('should create valid PinHash with required parameters', () {
        final pinHash = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 100000,
        );
        
        expect(pinHash.hash, equals(testHash));
        expect(pinHash.salt, equals(testSalt));
        expect(pinHash.iterations, equals(100000));
        expect(pinHash.algorithm, equals('PBKDF2-SHA256'));
        expect(pinHash.createdAt, isNotNull);
      });
      
      test('should create PinHash with custom algorithm and timestamp', () {
        final pinHash = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 200000,
          algorithm: 'PBKDF2-SHA512',
          createdAt: testCreatedAt,
        );
        
        expect(pinHash.algorithm, equals('PBKDF2-SHA512'));
        expect(pinHash.createdAt, equals(testCreatedAt));
      });
      
      test('should throw ArgumentError for empty hash', () {
        expect(
          () => PinHash.create(
            hash: Uint8List(0),
            salt: testSalt,
            iterations: 100000,
          ),
          throwsArgumentError,
        );
      });
      
      test('should throw ArgumentError for empty salt', () {
        expect(
          () => PinHash.create(
            hash: testHash,
            salt: Uint8List(0),
            iterations: 100000,
          ),
          throwsArgumentError,
        );
      });
      
      test('should throw ArgumentError for non-positive iterations', () {
        expect(
          () => PinHash.create(
            hash: testHash,
            salt: testSalt,
            iterations: 0,
          ),
          throwsArgumentError,
        );
        
        expect(
          () => PinHash.create(
            hash: testHash,
            salt: testSalt,
            iterations: -1,
          ),
          throwsArgumentError,
        );
      });
      
      test('should throw ArgumentError for empty algorithm', () {
        expect(
          () => PinHash.create(
            hash: testHash,
            salt: testSalt,
            iterations: 100000,
            algorithm: '',
          ),
          throwsArgumentError,
        );
      });
      
      test('should create independent copies of byte arrays', () {
        final originalHash = Uint8List.fromList([1, 2, 3, 4]);
        final originalSalt = Uint8List.fromList([5, 6, 7, 8]);
        
        final pinHash = PinHash.create(
          hash: originalHash,
          salt: originalSalt,
          iterations: 100000,
        );
        
        // Modify original arrays
        originalHash[0] = 99;
        originalSalt[0] = 99;
        
        // PinHash should be unaffected
        expect(pinHash.hash[0], equals(1));
        expect(pinHash.salt[0], equals(5));
      });
    });
    
    group('fromMap/toMap', () {
      test('should serialize and deserialize correctly', () {
        final original = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 150000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: testCreatedAt,
        );
        
        final map = original.toMap();
        final restored = PinHash.fromMap(map);
        
        expect(restored.hash, equals(original.hash));
        expect(restored.salt, equals(original.salt));
        expect(restored.iterations, equals(original.iterations));
        expect(restored.algorithm, equals(original.algorithm));
        expect(restored.createdAt, equals(original.createdAt));
      });
      
      test('should handle map with all required fields', () {
        final map = {
          'hash': [1, 2, 3, 4, 5, 6, 7, 8],
          'salt': [9, 10, 11, 12, 13, 14, 15, 16],
          'iterations': 175000,
          'algorithm': 'PBKDF2-SHA256',
          'createdAt': '2024-01-01T12:00:00.000',
        };
        
        final pinHash = PinHash.fromMap(map);
        
        expect(pinHash.hash, equals(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8])));
        expect(pinHash.salt, equals(Uint8List.fromList([9, 10, 11, 12, 13, 14, 15, 16])));
        expect(pinHash.iterations, equals(175000));
        expect(pinHash.algorithm, equals('PBKDF2-SHA256'));
        expect(pinHash.createdAt, equals(DateTime(2024, 1, 1, 12, 0, 0)));
      });
    });
    
    group('isSecure', () {
      test('should return true for secure parameters', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32), // 256 bits
          salt: Uint8List(16), // 128 bits
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.isSecure(), isTrue);
      });
      
      test('should return false for insufficient iterations', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(16),
          iterations: 50000, // Below minimum
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.isSecure(), isFalse);
      });
      
      test('should return false for short salt', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(8), // Below minimum 16 bytes
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.isSecure(), isFalse);
      });
      
      test('should return false for short hash', () {
        final pinHash = PinHash.create(
          hash: Uint8List(16), // Below minimum 32 bytes
          salt: Uint8List(16),
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.isSecure(), isFalse);
      });
      
      test('should return false for wrong algorithm', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(16),
          iterations: 100000,
          algorithm: 'MD5', // Insecure algorithm
        );
        
        expect(pinHash.isSecure(), isFalse);
      });
    });
    
    group('needsUpgrade', () {
      test('should return true for low iteration count', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(16),
          iterations: 150000, // Below recommended 200000
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.needsUpgrade(), isTrue);
      });
      
      test('should return true for old hash', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 400));
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(16),
          iterations: 200000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: oldDate,
        );
        
        expect(pinHash.needsUpgrade(), isTrue);
      });
      
      test('should return false for current parameters', () {
        final pinHash = PinHash.create(
          hash: Uint8List(32),
          salt: Uint8List(16),
          iterations: 200000,
          algorithm: 'PBKDF2-SHA256',
        );
        
        expect(pinHash.needsUpgrade(), isFalse);
      });
    });
    
    group('constantTimeEquals', () {
      test('should return true for identical arrays', () {
        final hash1 = Uint8List.fromList([1, 2, 3, 4]);
        final hash2 = Uint8List.fromList([1, 2, 3, 4]);
        
        final pinHash = PinHash.create(
          hash: hash1,
          salt: testSalt,
          iterations: 100000,
        );
        
        expect(pinHash.constantTimeEquals(hash2), isTrue);
      });
      
      test('should return false for different arrays', () {
        final hash1 = Uint8List.fromList([1, 2, 3, 4]);
        final hash2 = Uint8List.fromList([1, 2, 3, 5]);
        
        final pinHash = PinHash.create(
          hash: hash1,
          salt: testSalt,
          iterations: 100000,
        );
        
        expect(pinHash.constantTimeEquals(hash2), isFalse);
      });
      
      test('should return false for different length arrays', () {
        final hash1 = Uint8List.fromList([1, 2, 3, 4]);
        final hash2 = Uint8List.fromList([1, 2, 3]);
        
        final pinHash = PinHash.create(
          hash: hash1,
          salt: testSalt,
          iterations: 100000,
        );
        
        expect(pinHash.constantTimeEquals(hash2), isFalse);
      });
    });
    
    group('copyWithIterations', () {
      test('should create copy with updated iterations', () {
        final original = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: testCreatedAt,
        );
        
        final copy = original.copyWithIterations(200000);
        
        expect(copy.iterations, equals(200000));
        expect(copy.hash, equals(original.hash));
        expect(copy.salt, equals(original.salt));
        expect(copy.algorithm, equals(original.algorithm));
        expect(copy.createdAt, equals(original.createdAt));
      });
    });
    
    group('dispose', () {
      test('should clear sensitive arrays', () {
        final hash = Uint8List.fromList([1, 2, 3, 4]);
        final salt = Uint8List.fromList([5, 6, 7, 8]);
        
        final pinHash = PinHash.create(
          hash: hash,
          salt: salt,
          iterations: 100000,
        );
        
        pinHash.dispose();
        
        // Arrays should be zeroed
        expect(pinHash.hash.every((byte) => byte == 0), isTrue);
        expect(pinHash.salt.every((byte) => byte == 0), isTrue);
      });
    });
    
    group('equality and hashCode', () {
      test('should be equal for same values', () {
        final pinHash1 = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: testCreatedAt,
        );
        
        final pinHash2 = PinHash.create(
          hash: Uint8List.fromList(testHash),
          salt: Uint8List.fromList(testSalt),
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: testCreatedAt,
        );
        
        expect(pinHash1, equals(pinHash2));
        expect(pinHash1.hashCode, equals(pinHash2.hashCode));
      });
      
      test('should not be equal for different values', () {
        final pinHash1 = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 100000,
        );
        
        final pinHash2 = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 200000, // Different iterations
        );
        
        expect(pinHash1, isNot(equals(pinHash2)));
      });
    });
    
    group('toString', () {
      test('should not expose sensitive data', () {
        final pinHash = PinHash.create(
          hash: testHash,
          salt: testSalt,
          iterations: 100000,
          algorithm: 'PBKDF2-SHA256',
          createdAt: testCreatedAt,
        );
        
        final stringRep = pinHash.toString();
        
        // Should not contain actual hash or salt bytes
        expect(stringRep, isNot(contains('1')));
        expect(stringRep, isNot(contains('2')));
        expect(stringRep, contains('PBKDF2-SHA256'));
        expect(stringRep, contains('100000'));
      });
    });
  });
}