import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/random/secure_random.dart';
import 'dart:typed_data';

void main() {
  group('SecureRandom', () {
    late SecureRandom random;
    
    setUpAll(() {
      random = SecureRandom.instance;
    });
    
    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = SecureRandom.instance;
        final instance2 = SecureRandom.instance;
        
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), isTrue);
      });
    });
    
    group('Basic Random Generation', () {
      test('nextByte should generate values in range [0, 255]', () {
        for (int i = 0; i < 1000; i++) {
          final byte = random.nextByte();
          expect(byte, greaterThanOrEqualTo(0));
          expect(byte, lessThanOrEqualTo(255));
        }
      });
      
      test('nextInt should generate values in specified range', () {
        // Test small ranges
        for (int max = 2; max <= 256; max *= 2) {
          for (int i = 0; i < 100; i++) {
            final value = random.nextInt(max);
            expect(value, greaterThanOrEqualTo(0));
            expect(value, lessThan(max));
          }
        }
        
        // Test larger ranges
        for (int i = 0; i < 100; i++) {
          final value = random.nextInt(10000);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(10000));
        }
      });
      
      test('nextInt should throw for invalid arguments', () {
        expect(() => random.nextInt(0), throwsArgumentError);
        expect(() => random.nextInt(-1), throwsArgumentError);
      });
      
      test('nextBytes should generate correct length', () {
        for (int length = 1; length <= 100; length++) {
          final bytes = random.nextBytes(length);
          expect(bytes.length, equals(length));
          
          // Check all bytes are in valid range
          for (final byte in bytes) {
            expect(byte, greaterThanOrEqualTo(0));
            expect(byte, lessThanOrEqualTo(255));
          }
        }
      });
      
      test('nextBytes should throw for invalid length', () {
        expect(() => random.nextBytes(0), throwsArgumentError);
        expect(() => random.nextBytes(-1), throwsArgumentError);
      });
      
      test('nextBigInt should generate correct bit length', () {
        for (int bitLength = 1; bitLength <= 256; bitLength += 8) {
          final bigInt = random.nextBigInt(bitLength);
          
          // BigInt should be non-negative
          expect(bigInt >= BigInt.zero, isTrue);
          
          // Should not exceed maximum value for bit length
          final maxValue = (BigInt.one << bitLength) - BigInt.one;
          expect(bigInt <= maxValue, isTrue);
        }
      });
      
      test('nextBigInt should throw for invalid bit length', () {
        expect(() => random.nextBigInt(0), throwsArgumentError);
        expect(() => random.nextBigInt(-1), throwsArgumentError);
      });
      
      test('nextDouble should generate values in [0.0, 1.0)', () {
        for (int i = 0; i < 1000; i++) {
          final value = random.nextDouble();
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThan(1.0));
        }
      });
      
      test('nextBool should generate both true and false', () {
        Set<bool> results = {};
        
        // Generate enough samples to likely get both values
        for (int i = 0; i < 1000; i++) {
          results.add(random.nextBool());
          if (results.length == 2) break;
        }
        
        expect(results.contains(true), isTrue);
        expect(results.contains(false), isTrue);
      });
    });
    
    group('Specialized Generation', () {
      test('uniqueIntegers should generate unique values', () {
        const count = 10;
        const max = 50;
        
        final values = random.uniqueIntegers(count, max);
        
        expect(values.length, equals(count));
        expect(values.toSet().length, equals(count)); // All unique
        
        // All values in range
        for (final value in values) {
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(max));
        }
        
        // Should be sorted
        final sortedValues = [...values]..sort();
        expect(values, equals(sortedValues));
      });
      
      test('uniqueIntegers should throw when impossible', () {
        expect(() => random.uniqueIntegers(10, 5), throwsArgumentError);
      });
      
      test('shuffle should randomize list order', () {
        final original = List.generate(20, (i) => i);
        final toShuffle = [...original];
        
        random.shuffle(toShuffle);
        
        // Should contain same elements
        expect(toShuffle.toSet(), equals(original.toSet()));
        expect(toShuffle.length, equals(original.length));
        
        // Should be different order (very high probability)
        // Allow for small chance of same order in randomness
        bool isDifferent = false;
        for (int i = 0; i < original.length; i++) {
          if (original[i] != toShuffle[i]) {
            isDifferent = true;
            break;
          }
        }
        // With 20 elements, probability of same order is ~1 in 2.4 × 10^18
        expect(isDifferent, isTrue);
      });
    });
    
    group('GF256 Specific Generation', () {
      test('nextGF256Element should generate valid field elements', () {
        for (int i = 0; i < 1000; i++) {
          final element = random.nextGF256Element();
          expect(element, greaterThanOrEqualTo(0));
          expect(element, lessThanOrEqualTo(255));
        }
      });
      
      test('nextGF256Elements should generate list of valid elements', () {
        for (int count = 1; count <= 10; count++) {
          final elements = random.nextGF256Elements(count);
          
          expect(elements.length, equals(count));
          
          for (final element in elements) {
            expect(element, greaterThanOrEqualTo(0));
            expect(element, lessThanOrEqualTo(255));
          }
        }
      });
      
      test('nextNonZeroGF256Element should never generate zero', () {
        for (int i = 0; i < 1000; i++) {
          final element = random.nextNonZeroGF256Element();
          expect(element, greaterThan(0));
          expect(element, lessThanOrEqualTo(255));
        }
      });
    });
    
    group('Security and Cleanup', () {
      test('secureClear should execute without error', () {
        expect(() => random.secureClear(), returnsNormally);
      });
      
      test('reseed should execute without error', () {
        expect(() => random.reseed(), returnsNormally);
        
        // Should still generate valid values after reseed
        final byte = random.nextByte();
        expect(byte, greaterThanOrEqualTo(0));
        expect(byte, lessThanOrEqualTo(255));
      });
    });
    
    group('Randomness Quality', () {
      test('should generate uniform distribution for small ranges', () {
        const int samples = 10000;
        const int buckets = 10;
        final counts = List.filled(buckets, 0);
        
        for (int i = 0; i < samples; i++) {
          final value = random.nextInt(buckets);
          counts[value]++;
        }
        
        // Each bucket should have roughly samples/buckets values
        final expected = samples / buckets;
        final tolerance = expected * 0.1; // 10% tolerance
        
        for (int count in counts) {
          expect(count, greaterThan(expected - tolerance));
          expect(count, lessThan(expected + tolerance));
        }
      });
      
      test('consecutive values should be different', () {
        // Check that we don't generate identical consecutive values
        // (extremely unlikely with good randomness)
        int identicalCount = 0;
        int previousByte = random.nextByte();
        
        for (int i = 0; i < 1000; i++) {
          int currentByte = random.nextByte();
          if (currentByte == previousByte) {
            identicalCount++;
          }
          previousByte = currentByte;
        }
        
        // With good randomness, expect ~4 identical pairs in 1000 samples
        // Allow up to 50 for test stability
        expect(identicalCount, lessThan(50));
      });
      
      test('entropy mixing should affect output', () {
        // Reset and generate baseline
        random.reseed();
        final baseline = random.nextBytes(10);
        
        // Reset again and generate comparison
        random.reseed();
        final comparison = random.nextBytes(10);
        
        // Should be different due to entropy mixing
        // (probability of identical sequences is extremely low)
        expect(baseline, isNot(equals(comparison)));
      });
    });
    
    group('Edge Cases', () {
      test('should handle boundary values for nextInt', () {
        // Boundary case: max = 1
        for (int i = 0; i < 100; i++) {
          expect(random.nextInt(1), equals(0));
        }
        
        // Boundary case: max = 256 (power of 2)
        for (int i = 0; i < 100; i++) {
          final value = random.nextInt(256);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(256));
        }
        
        // Boundary case: max = 255
        for (int i = 0; i < 100; i++) {
          final value = random.nextInt(255);
          expect(value, greaterThanOrEqualTo(0));
          expect(value, lessThan(255));
        }
      });
      
      test('should handle single byte generation for nextBytes', () {
        final singleByte = random.nextBytes(1);
        expect(singleByte.length, equals(1));
        expect(singleByte[0], greaterThanOrEqualTo(0));
        expect(singleByte[0], lessThanOrEqualTo(255));
      });
      
      test('should handle single bit BigInt generation', () {
        final singleBit = random.nextBigInt(1);
        expect(singleBit >= BigInt.zero, isTrue);
        expect(singleBit <= BigInt.one, isTrue);
      });
    });
  });
}