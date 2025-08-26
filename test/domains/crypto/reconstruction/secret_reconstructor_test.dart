import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/reconstruction/secret_reconstructor.dart';
import 'package:srsecrets/domains/crypto/shares/share.dart';
import 'package:srsecrets/domains/crypto/finite_field/gf256.dart';
import 'dart:typed_data';

void main() {
  group('SecretReconstructor', () {
    group('Basic Reconstruction', () {
      test('should reconstruct secret from minimum shares', () {
        const secret = 42;
        const threshold = 3;
        
        // Create test polynomial: f(x) = 42 + 13x + 7x²
        final shares = [
          Share(x: 1, y: GF256.add(GF256.add(42, 13), 7)), // f(1) = 42 + 13 + 7
          Share(x: 2, y: GF256.add(GF256.add(42, GF256.multiply(13, 2)), GF256.multiply(7, GF256.multiply(2, 2)))), // f(2)
          Share(x: 3, y: GF256.add(GF256.add(42, GF256.multiply(13, 3)), GF256.multiply(7, GF256.multiply(3, 3)))), // f(3)
        ];
        
        final reconstructed = SecretReconstructor.reconstructSecret(shares);
        expect(reconstructed, equals(secret));
      });

      test('should reconstruct with more shares than threshold', () {
        const secret = 100;
        const threshold = 2;
        
        // Linear polynomial: f(x) = 100 + 50x
        final shares = [
          Share(x: 1, y: GF256.add(100, 50)), // f(1) = 150
          Share(x: 2, y: GF256.add(100, GF256.multiply(50, 2))), // f(2)
          Share(x: 3, y: GF256.add(100, GF256.multiply(50, 3))), // f(3)
          Share(x: 4, y: GF256.add(100, GF256.multiply(50, 4))), // f(4)
        ];
        
        final reconstructed = SecretReconstructor.reconstructSecret(shares);
        expect(reconstructed, equals(secret));
      });

      test('should handle edge case of secret = 0', () {
        const secret = 0;
        const threshold = 2;
        
        // f(x) = 0 + 17x
        final shares = [
          Share(x: 1, y: 17),
          Share(x: 5, y: GF256.multiply(17, 5)),
        ];
        
        final reconstructed = SecretReconstructor.reconstructSecret(shares);
        expect(reconstructed, equals(secret));
      });

      test('should handle edge case of secret = 255', () {
        const secret = 255;
        const threshold = 2;
        
        // f(x) = 255 + 1x
        final shares = [
          Share(x: 1, y: GF256.add(255, 1)), // 254
          Share(x: 2, y: GF256.add(255, 2)), // 253
        ];
        
        final reconstructed = SecretReconstructor.reconstructSecret(shares);
        expect(reconstructed, equals(secret));
      });
    });

    group('Error Handling', () {
      test('should throw on empty shares', () {
        expect(
          () => SecretReconstructor.reconstructSecret([]),
          throwsArgumentError,
        );
      });

      test('should throw on invalid shares', () {
        final shares = [
          Share(x: 0, y: 100), // Invalid: x cannot be 0
          Share(x: 1, y: 200),
        ];
        
        expect(
          () => SecretReconstructor.reconstructSecret(shares),
          throwsArgumentError,
        );
      });

      test('should throw on duplicate x values', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 1, y: 150), // Duplicate x value
          Share(x: 2, y: 200),
        ];
        
        expect(
          () => SecretReconstructor.reconstructSecret(shares),
          throwsArgumentError,
        );
      });

      test('should throw on shares with invalid field elements', () {
        final shares = [
          Share(x: 256, y: 100), // Invalid: x > 255
          Share(x: 2, y: 200),
        ];
        
        expect(
          () => SecretReconstructor.reconstructSecret(shares),
          throwsArgumentError,
        );
      });
    });

    group('Secure Share Reconstruction', () {
      test('should reconstruct from secure shares with valid HMAC', () {
        const secret = 75;
        const threshold = 2;
        const totalShares = 3;
        const version = 1;
        const identifier = 'test-secure-shares';
        
        final secureShares = [
          SecureShare(
            x: 1,
            y: GF256.add(secret, GF256.multiply(23, 1)),
            version: version,
            threshold: threshold,
            totalShares: totalShares,
            identifier: identifier,
            hmac: SecureShare.calculateHmac(
              x: 1,
              y: GF256.add(secret, GF256.multiply(23, 1)),
              threshold: threshold,
              totalShares: totalShares,
              version: version,
              identifier: identifier,
            ),
          ),
          SecureShare(
            x: 2,
            y: GF256.add(secret, GF256.multiply(23, 2)),
            version: version,
            threshold: threshold,
            totalShares: totalShares,
            identifier: identifier,
            hmac: SecureShare.calculateHmac(
              x: 2,
              y: GF256.add(secret, GF256.multiply(23, 2)),
              threshold: threshold,
              totalShares: totalShares,
              version: version,
              identifier: identifier,
            ),
          ),
        ];
        
        final reconstructed = SecretReconstructor.reconstructFromSecureShares(secureShares);
        expect(reconstructed, equals(secret));
      });

      test('should throw on inconsistent threshold', () {
        final secureShares = [
          SecureShare(
            x: 1,
            y: 100,
            version: 1,
            threshold: 2,
            totalShares: 3,
            hmac: Uint8List(32), // Dummy HMAC for test
          ),
          SecureShare(
            x: 2,
            y: 200,
            version: 1,
            threshold: 3, // Different threshold
            totalShares: 3,
            hmac: Uint8List(32),
          ),
        ];
        
        expect(
          () => SecretReconstructor.reconstructFromSecureShares(secureShares),
          throwsArgumentError,
        );
      });

      test('should throw on inconsistent totalShares', () {
        final secureShares = [
          SecureShare(
            x: 1,
            y: 100,
            version: 1,
            threshold: 2,
            totalShares: 3,
            hmac: Uint8List(32),
          ),
          SecureShare(
            x: 2,
            y: 200,
            version: 1,
            threshold: 2,
            totalShares: 4, // Different totalShares
            hmac: Uint8List(32),
          ),
        ];
        
        expect(
          () => SecretReconstructor.reconstructFromSecureShares(secureShares),
          throwsArgumentError,
        );
      });

      test('should throw on insufficient shares', () {
        final secureShares = [
          SecureShare(
            x: 1,
            y: 100,
            version: 1,
            threshold: 3,
            totalShares: 5,
            hmac: Uint8List(32),
          ),
        ]; // Only 1 share, but threshold is 3
        
        expect(
          () => SecretReconstructor.reconstructFromSecureShares(secureShares),
          throwsArgumentError,
        );
      });
    });

    group('ShareSet Reconstruction', () {
      test('should reconstruct multi-byte secret from share sets', () {
        final originalSecret = Uint8List.fromList([10, 20, 30]);
        const threshold = 2;
        const totalShares = 3;
        
        // Create share sets manually for testing
        final shareSets = <ShareSet>[];
        final createdAt = DateTime.now();
        const id = 'test-share-set';
        
        // For each participant
        for (int participant = 0; participant < totalShares; participant++) {
          final shares = <Share>[];
          
          // For each byte position
          for (int byteIndex = 0; byteIndex < originalSecret.length; byteIndex++) {
            final secret = originalSecret[byteIndex];
            final coefficient = 17 + byteIndex; // Simple test coefficient
            
            final x = participant + 1;
            final y = GF256.add(secret, GF256.multiply(coefficient, x));
            
            shares.add(Share(x: x, y: y));
          }
          
          final metadata = ShareSetMetadata(
            id: id,
            shareIndex: participant + 1,
            threshold: threshold,
            totalShares: totalShares,
            secretLength: originalSecret.length,
            createdAt: createdAt,
          );
          
          shareSets.add(ShareSet(shares: shares, metadata: metadata));
        }
        
        final reconstructed = SecretReconstructor.reconstructFromShareSets(
          shareSets.take(threshold).toList(),
        );
        
        expect(reconstructed, equals(originalSecret));
      });

      test('should throw on inconsistent metadata', () {
        final shareSets = [
          ShareSet(
            shares: [Share(x: 1, y: 100)],
            metadata: ShareSetMetadata(
              id: 'test-1',
              shareIndex: 1,
              threshold: 2,
              totalShares: 3,
              secretLength: 1,
              createdAt: DateTime.now(),
            ),
          ),
          ShareSet(
            shares: [Share(x: 2, y: 200)],
            metadata: ShareSetMetadata(
              id: 'test-2', // Different ID
              shareIndex: 2,
              threshold: 2,
              totalShares: 3,
              secretLength: 1,
              createdAt: DateTime.now(),
            ),
          ),
        ];
        
        expect(
          () => SecretReconstructor.reconstructFromShareSets(shareSets),
          throwsArgumentError,
        );
      });

      test('should throw on insufficient share sets', () {
        final shareSets = [
          ShareSet(
            shares: [Share(x: 1, y: 100)],
            metadata: ShareSetMetadata(
              id: 'test',
              shareIndex: 1,
              threshold: 3, // Need 3 but only have 1
              totalShares: 5,
              secretLength: 1,
              createdAt: DateTime.now(),
            ),
          ),
        ];
        
        expect(
          () => SecretReconstructor.reconstructFromShareSets(shareSets),
          throwsArgumentError,
        );
      });
    });

    group('Validation Methods', () {
      test('canReconstruct should return true for valid shares', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 2, y: 150),
          Share(x: 3, y: 200),
        ];
        
        expect(SecretReconstructor.canReconstruct(shares, 3), isTrue);
        expect(SecretReconstructor.canReconstruct(shares, 2), isTrue);
      });

      test('canReconstruct should return false for insufficient shares', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 2, y: 150),
        ];
        
        expect(SecretReconstructor.canReconstruct(shares, 3), isFalse);
      });

      test('canReconstruct should return false for invalid shares', () {
        final shares = [
          Share(x: 0, y: 100), // Invalid x
          Share(x: 2, y: 150),
          Share(x: 3, y: 200),
        ];
        
        expect(SecretReconstructor.canReconstruct(shares, 3), isFalse);
      });

      test('canReconstruct should return false for duplicate x values', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 1, y: 150), // Duplicate x
          Share(x: 3, y: 200),
        ];
        
        expect(SecretReconstructor.canReconstruct(shares, 3), isFalse);
      });
    });

    group('Reconstruction with Verification', () {
      test('should succeed with consistent shares', () {
        const secret = 88;
        final shares = [
          Share(x: 1, y: GF256.add(secret, 25)), // f(x) = 88 + 25x
          Share(x: 2, y: GF256.add(secret, GF256.multiply(25, 2))),
          Share(x: 3, y: GF256.add(secret, GF256.multiply(25, 3))),
          Share(x: 4, y: GF256.add(secret, GF256.multiply(25, 4))),
        ];
        
        final result = SecretReconstructor.reconstructWithVerification(
          shares: shares,
          threshold: 2,
        );
        
        expect(result.success, isTrue);
        expect(result.secret, equals(secret));
        expect(result.error, isNull);
      });

      test('should detect inconsistent shares', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 2, y: 150),
          Share(x: 3, y: 250), // Inconsistent with the pattern
        ];
        
        final result = SecretReconstructor.reconstructWithVerification(
          shares: shares,
          threshold: 2,
        );
        
        expect(result.success, isFalse);
        expect(result.error, contains('Inconsistent reconstruction'));
      });

      test('should handle insufficient shares', () {
        final shares = [Share(x: 1, y: 100)];
        
        final result = SecretReconstructor.reconstructWithVerification(
          shares: shares,
          threshold: 2,
        );
        
        expect(result.success, isFalse);
        expect(result.error, contains('Insufficient shares'));
      });
    });

    group('Progressive Reconstruction', () {
      test('should reconstruct progressively as shares are added', () {
        const secret = 77;
        const threshold = 3;
        
        final reconstructor = SecretReconstructor.createProgressive(
          threshold: threshold,
        );
        
        expect(reconstructor.isComplete, isFalse);
        expect(reconstructor.shareCount, equals(0));
        expect(reconstructor.progress, equals(0.0));
        
        // Add first share
        final share1 = Share(x: 1, y: GF256.add(secret, GF256.multiply(30, 1)));
        expect(reconstructor.addShare(share1), isFalse);
        expect(reconstructor.progress, closeTo(1/3, 0.01));
        
        // Add second share
        final share2 = Share(x: 2, y: GF256.add(secret, GF256.multiply(30, 2)));
        expect(reconstructor.addShare(share2), isFalse);
        expect(reconstructor.progress, closeTo(2/3, 0.01));
        
        // Add third share - should complete reconstruction
        final share3 = Share(x: 3, y: GF256.add(secret, GF256.multiply(30, 3)));
        expect(reconstructor.addShare(share3), isTrue);
        expect(reconstructor.isComplete, isTrue);
        expect(reconstructor.progress, equals(1.0));
        expect(reconstructor.secret, equals(secret));
      });

      test('should reject duplicate shares', () {
        final reconstructor = SecretReconstructor.createProgressive(threshold: 2);
        
        final share = Share(x: 1, y: 100);
        expect(reconstructor.addShare(share), isFalse);
        expect(reconstructor.addShare(share), isFalse); // Duplicate should be rejected
        expect(reconstructor.shareCount, equals(1));
      });

      test('should reset properly', () {
        final reconstructor = SecretReconstructor.createProgressive(threshold: 2);
        
        reconstructor.addShare(Share(x: 1, y: 100));
        reconstructor.addShare(Share(x: 2, y: 150));
        
        reconstructor.reset();
        
        expect(reconstructor.shareCount, equals(0));
        expect(reconstructor.isComplete, isFalse);
        expect(reconstructor.secret, isNull);
        expect(reconstructor.progress, equals(0.0));
      });

      test('should provide immutable share access', () {
        final reconstructor = SecretReconstructor.createProgressive(threshold: 2);
        
        reconstructor.addShare(Share(x: 1, y: 100));
        
        final shares = reconstructor.shares;
        expect(shares, hasLength(1));
        expect(shares.first.x, equals(1));
        
        // Should be immutable
        expect(() => shares.clear(), throwsUnsupportedError);
      });
    });

    group('Batch Reconstruction', () {
      test('should reconstruct multiple secrets', () {
        final secrets = [42, 100, 200];
        const threshold = 2;
        
        final shareGroups = <List<Share>>[];
        
        for (int i = 0; i < secrets.length; i++) {
          final secret = secrets[i];
          final coeff = 10 + i;
          
          shareGroups.add([
            Share(x: 1, y: GF256.add(secret, coeff)),
            Share(x: 2, y: GF256.add(secret, GF256.multiply(coeff, 2))),
          ]);
        }
        
        final results = BatchReconstructor.reconstructMultiple(
          shareGroups: shareGroups,
          threshold: threshold,
        );
        
        expect(results, equals(secrets));
      });

      test('should handle parallel reconstruction', () async {
        final secrets = [15, 30, 45];
        const threshold = 2;
        
        final shareGroups = <List<Share>>[];
        
        for (int i = 0; i < secrets.length; i++) {
          final secret = secrets[i];
          final coeff = 5 + i;
          
          shareGroups.add([
            Share(x: 1, y: GF256.add(secret, coeff)),
            Share(x: 2, y: GF256.add(secret, GF256.multiply(coeff, 2))),
          ]);
        }
        
        final results = await BatchReconstructor.reconstructParallel(
          shareGroups: shareGroups,
          threshold: threshold,
        );
        
        expect(results, equals(secrets));
      });

      test('should throw on insufficient shares in batch', () {
        final shareGroups = [
          [Share(x: 1, y: 100)], // Only 1 share, need 2
        ];
        
        expect(
          () => BatchReconstructor.reconstructMultiple(
            shareGroups: shareGroups,
            threshold: 2,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Integration Tests', () {
      test('should work with generated shares from ShareGenerator', () {
        const secret = 123;
        const threshold = 3;
        const totalShares = 5;
        
        // Generate shares using ShareGenerator
        final shares = ShareGenerator.generateShares(
          secret: secret,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        // Reconstruct using minimum shares
        final reconstructed = SecretReconstructor.reconstructSecret(
          shares.take(threshold).toList(),
        );
        
        expect(reconstructed, equals(secret));
        
        // Verify with different subset
        final reconstructed2 = SecretReconstructor.reconstructSecret(
          shares.skip(1).take(threshold).toList(),
        );
        
        expect(reconstructed2, equals(secret));
      });

      test('should work with real multi-byte secret end-to-end', () {
        const originalText = 'Hello, Crypto World!';
        final originalBytes = Uint8List.fromList(originalText.codeUnits);
        const threshold = 3;
        const totalShares = 5;
        
        // Generate share sets
        final shareSets = ShareGenerator.generateShareSets(
          secretBytes: originalBytes,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        // Reconstruct using minimum share sets
        final reconstructedBytes = SecretReconstructor.reconstructFromShareSets(
          shareSets.take(threshold).toList(),
        );
        
        final reconstructedText = String.fromCharCodes(reconstructedBytes);
        expect(reconstructedText, equals(originalText));
      });
    });
  });
}