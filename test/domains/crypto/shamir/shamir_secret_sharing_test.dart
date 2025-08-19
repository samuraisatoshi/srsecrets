import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/shamir/shamir_secret_sharing.dart';
import 'package:srsecrets/domains/crypto/shares/share.dart';
import 'package:srsecrets/domains/crypto/reconstruction/secret_reconstructor.dart';

void main() {
  group('Shamir Secret Sharing', () {
    group('Single Byte Secrets', () {
      test('Split and combine single byte', () {
        const secret = 42;
        const threshold = 3;
        const totalShares = 5;
        
        // Split the secret
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        expect(result.shares.length, equals(totalShares));
        expect(result.threshold, equals(threshold));
        
        // Verify all shares are valid
        for (final share in result.shares) {
          expect(share.isValid, isTrue);
          expect(share.hasValidHmac, isTrue);
        }
        
        // Reconstruct with minimum shares
        final minShares = result.shares
            .take(threshold)
            .map((s) => Share(x: s.x, y: s.y))
            .toList();
        
        final reconstructed = ShamirSecretSharing.combineByte(
          shares: minShares,
          threshold: threshold,
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Reconstruction with different share combinations', () {
        const secret = 123;
        const threshold = 3;
        const totalShares = 6;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Try different combinations of threshold shares
        final combinations = [
          [0, 1, 2],
          [1, 3, 5],
          [0, 2, 4],
          [2, 3, 4],
          [0, 3, 5],
        ];
        
        for (final indices in combinations) {
          final selectedShares = indices
              .map((i) => result.shares[i])
              .map((s) => Share(x: s.x, y: s.y))
              .toList();
          
          final reconstructed = ShamirSecretSharing.combineByte(
            shares: selectedShares,
            threshold: threshold,
          );
          
          expect(reconstructed, equals(secret),
              reason: 'Failed with indices $indices');
        }
      });
      
      test('All possible byte values', () {
        const threshold = 2;
        const totalShares = 3;
        
        // Test all possible byte values
        for (int secret = 0; secret < 256; secret++) {
          final result = ShamirSecretSharing.splitByte(
            secret: secret,
            threshold: threshold,
            shares: totalShares,
          );
          
          final minShares = result.shares
              .take(threshold)
              .map((s) => Share(x: s.x, y: s.y))
              .toList();
          
          final reconstructed = ShamirSecretSharing.combineByte(
            shares: minShares,
            threshold: threshold,
          );
          
          expect(reconstructed, equals(secret),
              reason: 'Failed for secret value $secret');
        }
      });
      
      test('Error cases for byte splitting', () {
        // Invalid secret value
        expect(
          () => ShamirSecretSharing.splitByte(
            secret: 256,
            threshold: 3,
            shares: 5,
          ),
          throwsArgumentError,
        );
        
        // Threshold too small
        expect(
          () => ShamirSecretSharing.splitByte(
            secret: 42,
            threshold: 1,
            shares: 5,
          ),
          throwsArgumentError,
        );
        
        // Threshold exceeds shares
        expect(
          () => ShamirSecretSharing.splitByte(
            secret: 42,
            threshold: 6,
            shares: 5,
          ),
          throwsArgumentError,
        );
        
        // Too many shares
        expect(
          () => ShamirSecretSharing.splitByte(
            secret: 42,
            threshold: 3,
            shares: 256,
          ),
          throwsArgumentError,
        );
      });
    });
    
    group('Byte Array Secrets', () {
      test('Split and combine byte array', () {
        final secret = Uint8List.fromList([1, 2, 3, 4, 5]);
        const threshold = 3;
        const totalShares = 5;
        
        // Split the secret
        final result = ShamirSecretSharing.splitBytes(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        expect(result.shareSets.length, equals(totalShares));
        expect(result.secretLength, equals(secret.length));
        
        // Reconstruct with minimum share sets
        final minShareSets = result.shareSets.take(threshold).toList();
        
        final reconstructed = ShamirSecretSharing.combineBytes(
          shareSets: minShareSets,
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Large byte array', () {
        // Create a larger secret (1KB)
        final secret = Uint8List(1024);
        for (int i = 0; i < secret.length; i++) {
          secret[i] = i % 256;
        }
        
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitBytes(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final minShareSets = result.shareSets.take(threshold).toList();
        
        final reconstructed = ShamirSecretSharing.combineBytes(
          shareSets: minShareSets,
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Empty byte array error', () {
        expect(
          () => ShamirSecretSharing.splitBytes(
            secret: Uint8List(0),
            threshold: 3,
            shares: 5,
          ),
          throwsArgumentError,
        );
      });
    });
    
    group('String Secrets', () {
      test('Split and combine string', () {
        const secret = 'Hello, Shamir Secret Sharing!';
        const threshold = 3;
        const totalShares = 5;
        
        // Split the secret
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        expect(result.metadata['type'], equals('string'));
        expect(result.metadata['encoding'], equals('utf8'));
        
        // Reconstruct
        final minShareSets = result.shareSets.take(threshold).toList();
        
        final reconstructed = ShamirSecretSharing.combineString(
          shareSets: minShareSets,
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Unicode string support', () {
        const secret = 'Hello 世界 🌍 مرحبا мир';
        const threshold = 2;
        const totalShares = 3;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final reconstructed = ShamirSecretSharing.combineString(
          shareSets: result.shareSets.take(threshold).toList(),
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Empty string error', () {
        expect(
          () => ShamirSecretSharing.splitString(
            secret: '',
            threshold: 3,
            shares: 5,
          ),
          throwsArgumentError,
        );
      });
    });
    
    group('Share Verification', () {
      test('Verify valid shares', () {
        const secret = 100;
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final shares = result.shares
            .map((s) => Share(x: s.x, y: s.y))
            .toList();
        
        // Verify with enough shares
        expect(
          ShamirSecretSharing.verifyShares(
            shares: shares.take(threshold).toList(),
            threshold: threshold,
          ),
          isTrue,
        );
        
        // Verify with more than enough shares
        expect(
          ShamirSecretSharing.verifyShares(
            shares: shares,
            threshold: threshold,
          ),
          isTrue,
        );
      });
      
      test('Verify insufficient shares', () {
        const secret = 100;
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final shares = result.shares
            .take(2) // Less than threshold
            .map((s) => Share(x: s.x, y: s.y))
            .toList();
        
        expect(
          ShamirSecretSharing.verifyShares(
            shares: shares,
            threshold: threshold,
          ),
          isFalse,
        );
      });
      
      test('Verify duplicate shares', () {
        const secret = 100;
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final firstShare = Share(
          x: result.shares[0].x,
          y: result.shares[0].y,
        );
        
        // Create duplicate shares
        final shares = [firstShare, firstShare, firstShare];
        
        expect(
          ShamirSecretSharing.verifyShares(
            shares: shares,
            threshold: threshold,
          ),
          isFalse,
        );
      });
    });
    
    group('Participant Packages', () {
      test('Create and use distribution packages', () {
        const secret = 'Secret message for distribution';
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Create distribution packages
        final packages = result.createDistributionPackages();
        
        expect(packages.length, equals(totalShares));
        
        // Verify each package
        for (int i = 0; i < packages.length; i++) {
          final package = packages[i];
          expect(package.participantNumber, equals(i + 1));
          expect(package.threshold, equals(threshold));
          expect(package.totalParticipants, equals(totalShares));
          expect(package.getInstructions(), contains('$threshold'));
        }
        
        // Export and import packages
        final exportedPackages = packages
            .map((p) => p.toBase64())
            .toList();
        
        final importedPackages = exportedPackages
            .map((b64) => ParticipantPackage.fromBase64(b64))
            .toList();
        
        // Reconstruct using imported packages
        final shareSetsForReconstruction = importedPackages
            .take(threshold)
            .map((p) => p.shareSet)
            .toList();
        
        final reconstructed = ShamirSecretSharing.combineString(
          shareSets: shareSetsForReconstruction,
        );
        
        expect(reconstructed, equals(secret));
      });
    });
    
    group('Interactive Session', () {
      test('Progressive share collection', () {
        const secret = 'Session secret';
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Create session
        final session = ShamirSecretSharing.createSession(
          threshold: threshold,
          totalShares: totalShares,
        );
        
        expect(session.progress, equals(0.0));
        expect(session.sharesNeeded, equals(threshold));
        expect(session.canReconstruct, isFalse);
        
        // Add shares progressively
        for (int i = 0; i < threshold; i++) {
          final added = session.addShareSet(result.shareSets[i]);
          
          if (i < threshold - 1) {
            expect(added, isFalse);
            expect(session.isReconstructed, isFalse);
            expect(session.sharesNeeded, equals(threshold - i - 1));
          } else {
            expect(added, isTrue);
            expect(session.isReconstructed, isTrue);
            expect(session.sharesNeeded, equals(0));
          }
          
          expect(session.sharesCollected, equals(i + 1));
        }
        
        expect(session.secretString, equals(secret));
        expect(session.progress, equals(1.0));
        
        // Test status
        final status = session.getStatus();
        expect(status['isReconstructed'], isTrue);
        expect(status['canReconstruct'], isTrue);
      });
      
      test('Session with duplicate shares', () {
        const secret = 'Test duplicate';
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final session = ShamirSecretSharing.createSession(
          threshold: threshold,
          totalShares: totalShares,
        );
        
        // Add same share twice
        session.addShareSet(result.shareSets[0]);
        final duplicateAdded = session.addShareSet(result.shareSets[0]);
        
        expect(duplicateAdded, isFalse);
        expect(session.sharesCollected, equals(1));
      });
      
      test('Session reset', () {
        const secret = 'Reset test';
        const threshold = 2;
        const totalShares = 3;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        final session = ShamirSecretSharing.createSession(
          threshold: threshold,
          totalShares: totalShares,
        );
        
        // Add shares and reconstruct
        session.addShareSet(result.shareSets[0]);
        session.addShareSet(result.shareSets[1]);
        
        expect(session.isReconstructed, isTrue);
        expect(session.secretString, equals(secret));
        
        // Reset session
        session.reset();
        
        expect(session.isReconstructed, isFalse);
        expect(session.sharesCollected, equals(0));
        expect(session.secretString, isNull);
        expect(session.progress, equals(0.0));
      });
    });
    
    group('Serialization', () {
      test('Share serialization to JSON and back', () {
        const secret = 42;
        const threshold = 2;
        const totalShares = 3;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Export to JSON
        final jsonShares = result.toJson();
        
        // Import from JSON
        final importedShares = jsonShares
            .map((json) => SecureShare.fromJson(json))
            .toList();
        
        // Verify imported shares
        for (int i = 0; i < importedShares.length; i++) {
          expect(importedShares[i].x, equals(result.shares[i].x));
          expect(importedShares[i].y, equals(result.shares[i].y));
          expect(importedShares[i].threshold, equals(threshold));
          expect(importedShares[i].totalShares, equals(totalShares));
        }
        
        // Reconstruct from imported shares
        final reconstructed = ShamirSecretSharing.combineByte(
          shares: importedShares
              .take(threshold)
              .map((s) => Share(x: s.x, y: s.y))
              .toList(),
          threshold: threshold,
        );
        
        expect(reconstructed, equals(secret));
      });
      
      test('Share serialization to Base64 and back', () {
        const secret = 'Base64 test';
        const threshold = 2;
        const totalShares = 3;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Export to Base64
        final base64Shares = result.toBase64List();
        
        // Import from Base64
        final importedShareSets = base64Shares
            .map((b64) => ShareSet.fromBase64(b64))
            .toList();
        
        // Reconstruct from imported share sets
        final reconstructed = ShamirSecretSharing.combineString(
          shareSets: importedShareSets.take(threshold).toList(),
        );
        
        expect(reconstructed, equals(secret));
      });
    });
    
    group('Security Properties', () {
      test('Share independence', () {
        const secret = 200;
        const threshold = 3;
        const totalShares = 5;
        
        // Generate multiple splits of the same secret
        final results = <SplitResult>[];
        for (int i = 0; i < 10; i++) {
          results.add(ShamirSecretSharing.splitByte(
            secret: secret,
            threshold: threshold,
            shares: totalShares,
          ));
        }
        
        // Verify that shares are different across splits
        for (int i = 0; i < results.length - 1; i++) {
          for (int j = 0; j < totalShares; j++) {
            // Y values should be different (with high probability)
            // due to random polynomial coefficients
            expect(
              results[i].shares[j].y != results[i + 1].shares[j].y,
              isTrue,
              reason: 'Shares should be different across splits',
            );
          }
        }
      });
      
      test('Insufficient shares reveal nothing', () {
        const secret = 150;
        const threshold = 3;
        const totalShares = 5;
        
        final result = ShamirSecretSharing.splitByte(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        // Try with threshold-1 shares
        final insufficientShares = result.shares
            .take(threshold - 1)
            .map((s) => Share(x: s.x, y: s.y))
            .toList();
        
        // Should throw error when trying to reconstruct
        expect(
          () => ShamirSecretSharing.combineByte(
            shares: insufficientShares,
            threshold: threshold,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}