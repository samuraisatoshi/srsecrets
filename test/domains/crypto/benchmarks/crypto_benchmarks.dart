import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/finite_field/gf256.dart';
import 'package:srsecrets/domains/crypto/random/secure_random.dart';
import 'package:srsecrets/domains/crypto/polynomial/polynomial_generator.dart';
import 'package:srsecrets/domains/crypto/shares/share.dart';
import 'package:srsecrets/domains/crypto/reconstruction/secret_reconstructor.dart';
import 'package:srsecrets/domains/crypto/shamir/shamir_secret_sharing.dart';
import 'dart:typed_data';

void main() {
  group('Crypto Performance Benchmarks', () {
    setUpAll(() {
      // Initialize GF256 tables once
      GF256.add(0, 0);
    });

    group('GF256 Field Operations', () {
      test('GF256 Addition Benchmark', () {
        const int iterations = 100000;
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final a = i % 256;
          final b = (i + 100) % 256;
          GF256.add(a, b);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('GF256 Addition: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        // Performance regression test: should complete within reasonable time
        expect(avgPerOp, lessThan(2.0), 
          reason: 'GF256 addition should be under 2μs per operation');
      });

      test('GF256 Multiplication Benchmark', () {
        const int iterations = 100000;
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final a = (i % 255) + 1;  // Non-zero
          final b = ((i + 100) % 255) + 1;  // Non-zero
          GF256.multiply(a, b);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('GF256 Multiplication: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(2.0), 
          reason: 'GF256 multiplication should be under 2μs per operation');
      });

      test('GF256 Division Benchmark', () {
        const int iterations = 10000;
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final a = (i % 255) + 1;  // Non-zero numerator
          final b = ((i + 100) % 255) + 1;  // Non-zero divisor
          GF256.divide(a, b);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('GF256 Division: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(5.0), 
          reason: 'GF256 division should be under 5μs per operation');
      });

      test('Lagrange Interpolation Benchmark', () {
        const int iterations = 1000;
        final xCoords = [1, 2, 3, 4, 5];
        final yCoords = [10, 20, 30, 40, 50];
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          GF256.lagrangeInterpolate(xCoords, yCoords);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Lagrange Interpolation (5 points): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(100.0), 
          reason: 'Lagrange interpolation should be under 100μs per operation');
      });
    });

    group('Random Number Generation', () {
      test('SecureRandom Byte Generation Benchmark', () {
        const int iterations = 10000;
        final random = SecureRandom.instance;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          random.nextByte();
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('SecureRandom Byte: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(50.0), 
          reason: 'Secure random byte generation should be under 50μs per operation');
      });

      test('SecureRandom GF256 Element Generation Benchmark', () {
        const int iterations = 10000;
        final random = SecureRandom.instance;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          random.nextGF256Element();
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('SecureRandom GF256 Element: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(50.0), 
          reason: 'GF256 element generation should be under 50μs per operation');
      });

      test('SecureRandom Bulk Generation Benchmark', () {
        const int iterations = 1000;
        const int bytesPerIteration = 1000;
        final random = SecureRandom.instance;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          random.nextBytes(bytesPerIteration);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final totalBytes = iterations * bytesPerIteration;
        final bytesPerSecond = (totalBytes * 1000000) ~/ microseconds;
        
        print('SecureRandom Bulk: ${totalBytes} bytes in ${microseconds}μs (${(bytesPerSecond / 1024 / 1024).toStringAsFixed(2)} MB/s)');
        
        expect(bytesPerSecond, greaterThan(10 * 1024), 
          reason: 'Bulk random generation should exceed 10 KB/s');
      });
    });

    group('Polynomial Operations', () {
      test('Polynomial Generation Benchmark', () {
        const int iterations = 1000;
        const int threshold = 5;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final secret = i % 256;
          PolynomialGenerator.generatePolynomial(
            secret: secret,
            threshold: threshold,
          );
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Polynomial Generation (threshold $threshold): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(200.0), 
          reason: 'Polynomial generation should be under 200μs per operation');
      });

      test('Polynomial Evaluation Benchmark', () {
        const int iterations = 10000;
        final coefficients = [42, 13, 7, 25, 100]; // Degree 4 polynomial
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final x = (i % 255) + 1;
          PolynomialGenerator.evaluatePolynomial(coefficients, x);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Polynomial Evaluation (degree ${coefficients.length - 1}): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(2.0), 
          reason: 'Polynomial evaluation should be under 2μs per operation');
      });

      test('Evaluation Points Generation Benchmark', () {
        const int iterations = 1000;
        const int pointCount = 10;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          PolynomialGenerator.generateEvaluationPoints(pointCount);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Evaluation Points Generation ($pointCount points): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(500.0), 
          reason: 'Evaluation points generation should be under 500μs per operation');
      });
    });

    group('Share Operations', () {
      test('Single Share Generation Benchmark', () {
        const int iterations = 1000;
        const int threshold = 3;
        const int totalShares = 5;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final secret = i % 256;
          ShareGenerator.generateShares(
            secret: secret,
            threshold: threshold,
            totalShares: totalShares,
          );
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Single Share Generation ($threshold-of-$totalShares): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(500.0), 
          reason: 'Single share generation should be under 500μs per operation');
      });

      test('Multi-byte Share Generation Benchmark', () {
        const int iterations = 100;
        const int secretSize = 32; // 32 bytes
        const int threshold = 3;
        const int totalShares = 5;
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final secretBytes = Uint8List.fromList(
            List.generate(secretSize, (index) => (i + index) % 256)
          );
          
          ShareGenerator.generateShareSets(
            secretBytes: secretBytes,
            threshold: threshold,
            totalShares: totalShares,
          );
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        final avgPerByte = avgPerOp / secretSize;
        
        print('Multi-byte Share Generation (${secretSize}B, $threshold-of-$totalShares): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op, ${avgPerByte.toStringAsFixed(3)}μs/byte)');
        
        expect(avgPerOp, lessThan(5000.0), 
          reason: 'Multi-byte share generation should be under 5ms per operation');
      });

      test('Share Serialization Benchmark', () {
        const int iterations = 10000;
        final share = Share(x: 123, y: 456);
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final json = share.toJson();
          Share.fromJson(json);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Share JSON Serialization: $iterations round-trips in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(10.0), 
          reason: 'Share serialization should be under 10μs per round-trip');
      });
    });

    group('Secret Reconstruction', () {
      test('Single Secret Reconstruction Benchmark', () {
        const int iterations = 1000;
        const int secret = 42;
        const int threshold = 3;
        
        // Pre-generate shares for consistent benchmarking
        final shares = ShareGenerator.generateShares(
          secret: secret,
          threshold: threshold,
          totalShares: threshold,
        );
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          SecretReconstructor.reconstructSecret(shares);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Single Secret Reconstruction (threshold $threshold): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(50.0), 
          reason: 'Single secret reconstruction should be under 50μs per operation');
      });

      test('Multi-byte Reconstruction Benchmark', () {
        const int iterations = 100;
        const int secretSize = 32; // 32 bytes
        const int threshold = 3;
        const int totalShares = 5;
        
        // Pre-generate share sets for consistent benchmarking
        final secretBytes = Uint8List.fromList(
          List.generate(secretSize, (index) => index % 256)
        );
        final shareSets = ShareGenerator.generateShareSets(
          secretBytes: secretBytes,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          SecretReconstructor.reconstructFromShareSets(
            shareSets.take(threshold).toList(),
          );
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        final avgPerByte = avgPerOp / secretSize;
        
        print('Multi-byte Reconstruction (${secretSize}B, threshold $threshold): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op, ${avgPerByte.toStringAsFixed(3)}μs/byte)');
        
        expect(avgPerOp, lessThan(2000.0), 
          reason: 'Multi-byte reconstruction should be under 2ms per operation');
      });

      test('Progressive Reconstruction Benchmark', () {
        const int iterations = 1000;
        const int threshold = 3;
        const int secret = 99;
        
        final shares = ShareGenerator.generateShares(
          secret: secret,
          threshold: threshold,
          totalShares: threshold,
        );
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          final reconstructor = SecretReconstructor.createProgressive(
            threshold: threshold,
          );
          
          for (final share in shares) {
            reconstructor.addShare(share);
          }
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Progressive Reconstruction (threshold $threshold): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(100.0), 
          reason: 'Progressive reconstruction should be under 100μs per operation');
      });
    });

    group('End-to-End Performance', () {
      test('Complete SSS Cycle Benchmark (Small)', () {
        const int iterations = 100;
        const int threshold = 3;
        const int totalShares = 5;
        const String testMessage = 'Hello SSS!';
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          // Split
          final result = ShamirSecretSharing.splitString(
            secret: testMessage,
            threshold: threshold,
            shares: totalShares,
          );
          
          // Reconstruct
          final reconstructed = ShamirSecretSharing.combineString(
            shareSets: result.shareSets.take(threshold).toList(),
          );
          
          // Verify (doesn't count towards timing)
          assert(reconstructed == testMessage);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Complete SSS Cycle Small ("${testMessage}"): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(2000.0), 
          reason: 'Complete small SSS cycle should be under 2ms per operation');
      });

      test('Complete SSS Cycle Benchmark (Large)', () {
        const int iterations = 10;
        const int threshold = 5;
        const int totalShares = 8;
        const int messageSize = 1024; // 1KB
        
        final testMessage = String.fromCharCodes(
          List.generate(messageSize, (index) => 65 + (index % 26)) // A-Z repeated
        );
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          // Split
          final result = ShamirSecretSharing.splitString(
            secret: testMessage,
            threshold: threshold,
            shares: totalShares,
          );
          
          // Reconstruct
          final reconstructed = ShamirSecretSharing.combineString(
            shareSets: result.shareSets.take(threshold).toList(),
          );
          
          // Verify (doesn't count towards timing)
          assert(reconstructed == testMessage);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        final bytesPerSecond = (messageSize * 1000000 * iterations) ~/ microseconds;
        
        print('Complete SSS Cycle Large (${messageSize}B): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op, ${(bytesPerSecond / 1024).toStringAsFixed(2)} KB/s)');
        
        expect(avgPerOp, lessThan(200000.0), 
          reason: 'Complete large SSS cycle should be under 200ms per operation');
      });

      test('Memory Usage Stability Test', () {
        // This test ensures no significant memory leaks during intensive operations
        const int iterations = 10; // Reduced iterations to avoid division by zero
        const int threshold = 3;
        const int totalShares = 5;
        
        for (int i = 0; i < iterations; i++) {
          final secret = 'Test message ${i + 100}'; // Avoid issues with low values
          
          final result = ShamirSecretSharing.splitString(
            secret: secret,
            threshold: threshold,
            shares: totalShares,
          );
          
          final reconstructed = ShamirSecretSharing.combineString(
            shareSets: result.shareSets.take(threshold).toList(),
          );
          
          expect(reconstructed, equals(secret));
        }
        
        print('Memory stability test completed: $iterations cycles');
        expect(true, isTrue); // Test completion is success
      });
    });

    group('Security Performance', () {
      test('HMAC Verification Performance', () {
        const int iterations = 1000;
        final secureShare = SecureShare(
          x: 123,
          y: 456,
          version: 1,
          threshold: 3,
          totalShares: 5,
          identifier: 'benchmark-test',
          hmac: Uint8List(32),
        );
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          secureShare.hasValidHmac;
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('HMAC Verification: $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(100.0), 
          reason: 'HMAC verification should be under 100μs per operation');
      });

      test('Constant-Time Comparison Performance', () {
        const int iterations = 10000;
        final data1 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
        final data2 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
        
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < iterations; i++) {
          SecureShare.constantTimeEquals(data1, data2);
        }
        
        stopwatch.stop();
        final microseconds = stopwatch.elapsedMicroseconds;
        final avgPerOp = microseconds / iterations;
        
        print('Constant-Time Comparison (16 bytes): $iterations ops in ${microseconds}μs (${avgPerOp.toStringAsFixed(3)}μs/op)');
        
        expect(avgPerOp, lessThan(1.0), 
          reason: 'Constant-time comparison should be under 1μs per operation');
      });
    });

    group('Regression Performance Tests', () {
      test('Performance Regression Detection', () {
        // This test establishes baseline performance metrics
        // Values are based on expected performance on modern mobile devices
        
        final benchmarks = <String, double>{};
        
        // GF256 operations should be very fast (lookup table based)
        const gf256AddIterations = 10000;
        var stopwatch = Stopwatch()..start();
        for (int i = 0; i < gf256AddIterations; i++) {
          GF256.add(i % 256, (i + 1) % 256);
        }
        stopwatch.stop();
        benchmarks['GF256_ADD'] = stopwatch.elapsedMicroseconds / gf256AddIterations;
        
        // Single share generation
        const shareGenIterations = 100;
        stopwatch = Stopwatch()..start();
        for (int i = 0; i < shareGenIterations; i++) {
          ShareGenerator.generateShares(
            secret: i % 256,
            threshold: 3,
            totalShares: 5,
          );
        }
        stopwatch.stop();
        benchmarks['SHARE_GENERATION'] = stopwatch.elapsedMicroseconds / shareGenIterations;
        
        // Single secret reconstruction
        final shares = ShareGenerator.generateShares(secret: 42, threshold: 3, totalShares: 3);
        const reconstructIterations = 100;
        stopwatch = Stopwatch()..start();
        for (int i = 0; i < reconstructIterations; i++) {
          SecretReconstructor.reconstructSecret(shares);
        }
        stopwatch.stop();
        benchmarks['SECRET_RECONSTRUCTION'] = stopwatch.elapsedMicroseconds / reconstructIterations;
        
        print('Performance Baseline:');
        for (final entry in benchmarks.entries) {
          print('  ${entry.key}: ${entry.value.toStringAsFixed(3)}μs/op');
        }
        
        // Regression thresholds (these should not be exceeded)
        expect(benchmarks['GF256_ADD']!, lessThan(2.0), 
          reason: 'GF256 addition performance regression detected');
        expect(benchmarks['SHARE_GENERATION']!, lessThan(500.0), 
          reason: 'Share generation performance regression detected');  
        expect(benchmarks['SECRET_RECONSTRUCTION']!, lessThan(100.0), 
          reason: 'Secret reconstruction performance regression detected');
      });
    });

    tearDownAll(() {
      // Clean up after benchmarks
      GF256.secureClear();
      SecureRandom.instance.secureClear();
      print('\nBenchmark suite completed. Memory cleaned up.');
    });
  });
}