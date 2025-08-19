import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/domains/crypto/shares/share.dart';
import 'package:srsecrets/domains/crypto/finite_field/gf256.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  group('Share', () {
    group('Basic Share Operations', () {
      test('should create valid share', () {
        const share = Share(x: 1, y: 42);
        
        expect(share.x, equals(1));
        expect(share.y, equals(42));
        expect(share.metadata, isNull);
        expect(share.isValid, isTrue);
      });
      
      test('should create share with metadata', () {
        final metadata = {'description': 'test share', 'index': 1};
        final share = Share(x: 5, y: 100, metadata: metadata);
        
        expect(share.x, equals(5));
        expect(share.y, equals(100));
        expect(share.metadata, equals(metadata));
        expect(share.isValid, isTrue);
      });
      
      test('should validate share correctness', () {
        // Valid shares
        expect(Share(x: 1, y: 0).isValid, isTrue);
        expect(Share(x: 255, y: 255).isValid, isTrue);
        expect(Share(x: 128, y: 64).isValid, isTrue);
        
        // Invalid shares (x = 0 is reserved)
        expect(Share(x: 0, y: 42).isValid, isFalse);
        
        // Invalid shares (out of GF256 range)
        expect(Share(x: 256, y: 42).isValid, isFalse);
        expect(Share(x: 42, y: 256).isValid, isFalse);
        expect(Share(x: -1, y: 42).isValid, isFalse);
        expect(Share(x: 42, y: -1).isValid, isFalse);
      });
      
      test('should implement equality correctly', () {
        const share1 = Share(x: 1, y: 42);
        const share2 = Share(x: 1, y: 42);
        const share3 = Share(x: 2, y: 42);
        const share4 = Share(x: 1, y: 43);
        
        expect(share1, equals(share2));
        expect(share1.hashCode, equals(share2.hashCode));
        
        expect(share1, isNot(equals(share3)));
        expect(share1, isNot(equals(share4)));
        
        // Test with metadata (equality ignores metadata)
        final shareWithMeta = Share(x: 1, y: 42, metadata: {'test': true});
        expect(share1, equals(shareWithMeta));
      });
      
      test('should provide meaningful toString', () {
        const share = Share(x: 10, y: 200);
        final str = share.toString();
        
        expect(str, contains('10'));
        expect(str, contains('200'));
        expect(str, contains('Share'));
      });
    });
    
    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        const share = Share(x: 15, y: 200);
        final json = share.toJson();
        
        expect(json['x'], equals(15));
        expect(json['y'], equals(200));
        expect(json.containsKey('metadata'), isFalse);
      });
      
      test('should serialize with metadata to JSON', () {
        final metadata = {'description': 'test', 'priority': 1};
        final share = Share(x: 25, y: 150, metadata: metadata);
        final json = share.toJson();
        
        expect(json['x'], equals(25));
        expect(json['y'], equals(150));
        expect(json['metadata'], equals(metadata));
      });
      
      test('should deserialize from JSON correctly', () {
        final json = {'x': 30, 'y': 180};
        final share = Share.fromJson(json);
        
        expect(share.x, equals(30));
        expect(share.y, equals(180));
        expect(share.metadata, isNull);
      });
      
      test('should deserialize from JSON with metadata', () {
        final metadata = {'test': true, 'value': 42};
        final json = {'x': 35, 'y': 220, 'metadata': metadata};
        final share = Share.fromJson(json);
        
        expect(share.x, equals(35));
        expect(share.y, equals(220));
        expect(share.metadata, equals(metadata));
      });
      
      test('should throw on invalid JSON', () {
        expect(() => Share.fromJson({}), throwsArgumentError);
        expect(() => Share.fromJson({'x': 1}), throwsArgumentError);
        expect(() => Share.fromJson({'y': 1}), throwsArgumentError);
      });
      
      test('should roundtrip through JSON', () {
        final original = Share(
          x: 50, 
          y: 100, 
          metadata: {'test': 'value', 'number': 123},
        );
        
        final json = original.toJson();
        final restored = Share.fromJson(json);
        
        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.metadata, equals(original.metadata));
        expect(restored, equals(original));
      });
    });
    
    group('Base64 Serialization', () {
      test('should serialize to Base64', () {
        const share = Share(x: 77, y: 88);
        final base64 = share.toBase64();
        
        expect(base64, isA<String>());
        expect(base64.isNotEmpty, isTrue);
        
        // Should be valid base64
        expect(() => base64Decode(base64), returnsNormally);
      });
      
      test('should deserialize from Base64', () {
        const original = Share(x: 99, y: 111);
        final base64 = original.toBase64();
        final restored = Share.fromBase64(base64);
        
        expect(restored, equals(original));
      });
      
      test('should roundtrip through Base64 with metadata', () {
        final original = Share(
          x: 123,
          y: 234,
          metadata: {'key': 'value', 'number': 456},
        );
        
        final base64 = original.toBase64();
        final restored = Share.fromBase64(base64);
        
        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.metadata, equals(original.metadata));
      });
      
      test('should throw on invalid Base64', () {
        expect(() => Share.fromBase64('invalid!@#'), throwsException);
        expect(() => Share.fromBase64(''), throwsException);
      });
    });
  });
  
  group('SecureShare', () {
    group('Basic SecureShare Operations', () {
      test('should create secure share with all fields', () {
        final hmac = Uint8List.fromList(List.generate(32, (i) => i)); // Mock HMAC
        final share = SecureShare(
          x: 10,
          y: 20,
          version: 1,
          threshold: 3,
          totalShares: 5,
          identifier: 'test-share',
          hmac: hmac,
        );
        
        expect(share.x, equals(10));
        expect(share.y, equals(20));
        expect(share.version, equals(1));
        expect(share.threshold, equals(3));
        expect(share.totalShares, equals(5));
        expect(share.identifier, equals('test-share'));
        expect(share.hmac, equals(hmac));
        expect(share.isValid, isTrue);
      });
      
      test('should create secure share with minimal fields', () {
        const share = SecureShare(
          x: 15,
          y: 25,
          version: 2,
          threshold: 4,
          totalShares: 7,
        );
        
        expect(share.x, equals(15));
        expect(share.y, equals(25));
        expect(share.version, equals(2));
        expect(share.threshold, equals(4));
        expect(share.totalShares, equals(7));
        expect(share.identifier, isNull);
        expect(share.hmac, isNull);
      });
    });
    
    group('HMAC Operations', () {
      test('should calculate HMAC correctly', () {
        final hmac1 = SecureShare.calculateHmac(
          x: 1,
          y: 2,
          threshold: 3,
          totalShares: 4,
          version: 1,
          identifier: 'test',
        );
        
        final hmac2 = SecureShare.calculateHmac(
          x: 1,
          y: 2,
          threshold: 3,
          totalShares: 4,
          version: 1,
          identifier: 'test',
        );
        
        expect(hmac1, equals(hmac2)); // Deterministic
        expect(hmac1.length, equals(32)); // SHA-256 produces 32-byte hash
        
        // Different inputs should give different HMACs
        final hmac3 = SecureShare.calculateHmac(
          x: 1,
          y: 2,
          threshold: 3,
          totalShares: 5, // Different totalShares
          version: 1,
          identifier: 'test',
        );
        expect(hmac1, isNot(equals(hmac3)));
      });
      
      test('should calculate different HMACs for different identifiers', () {
        final hmac1 = SecureShare.calculateHmac(
          x: 10,
          y: 20,
          threshold: 3,
          totalShares: 5,
          version: 1,
          identifier: 'id1',
        );
        
        final hmac2 = SecureShare.calculateHmac(
          x: 10,
          y: 20,
          threshold: 3,
          totalShares: 5,
          version: 1,
          identifier: 'id2',
        );
        
        expect(hmac1, isNot(equals(hmac2)));
      });
      
      test('should handle null identifier consistently', () {
        final hmac1 = SecureShare.calculateHmac(
          x: 10,
          y: 20,
          threshold: 3,
          totalShares: 5,
          version: 1,
          identifier: null,
        );
        
        final hmac2 = SecureShare.calculateHmac(
          x: 10,
          y: 20,
          threshold: 3,
          totalShares: 5,
          version: 1,
          identifier: null,
        );
        
        expect(hmac1, equals(hmac2)); // Should be deterministic
      });
      
      test('should validate HMAC correctly', () {
        const x = 10, y = 20, threshold = 3, totalShares = 5, version = 1;
        const identifier = 'test-id';
        
        final correctHmac = SecureShare.calculateHmac(
          x: x,
          y: y,
          threshold: threshold,
          totalShares: totalShares,
          version: version,
          identifier: identifier,
        );
        
        final validShare = SecureShare(
          x: x,
          y: y,
          version: version,
          threshold: threshold,
          totalShares: totalShares,
          identifier: identifier,
          hmac: correctHmac,
        );
        
        expect(validShare.hasValidHmac, isTrue);
        
        // Invalid HMAC (modified)
        final invalidHmac = Uint8List.fromList(correctHmac);
        invalidHmac[0] = invalidHmac[0] ^ 1; // Flip one bit
        
        final invalidShare = SecureShare(
          x: x,
          y: y,
          version: version,
          threshold: threshold,
          totalShares: totalShares,
          identifier: identifier,
          hmac: invalidHmac,
        );
        
        expect(invalidShare.hasValidHmac, isFalse);
        
        // No HMAC (should be valid for backward compatibility)
        final noHmacShare = SecureShare(
          x: x,
          y: y,
          version: version,
          threshold: threshold,
          totalShares: totalShares,
          identifier: identifier,
        );
        
        expect(noHmacShare.hasValidHmac, isTrue);
      });
      
      test('should perform constant-time comparison', () {
        // Test that constant-time comparison works correctly
        final a = Uint8List.fromList([1, 2, 3, 4]);
        final b = Uint8List.fromList([1, 2, 3, 4]);
        final c = Uint8List.fromList([1, 2, 3, 5]);
        final d = Uint8List.fromList([1, 2, 3]); // Different length
        
        expect(SecureShare.constantTimeEquals(a, b), isTrue);
        expect(SecureShare.constantTimeEquals(a, c), isFalse);
        expect(SecureShare.constantTimeEquals(a, d), isFalse);
      });
    });
    
    group('SecureShare JSON Serialization', () {
      test('should serialize complete secure share to JSON', () {
        final hmac = Uint8List.fromList(List.generate(32, (i) => i + 10));
        final share = SecureShare(
          x: 30,
          y: 40,
          version: 1,
          threshold: 4,
          totalShares: 7,
          identifier: 'test-id',
          hmac: hmac,
        );
        
        final json = share.toJson();
        
        expect(json['x'], equals(30));
        expect(json['y'], equals(40));
        expect(json['version'], equals(1));
        expect(json['threshold'], equals(4));
        expect(json['totalShares'], equals(7));
        expect(json['identifier'], equals('test-id'));
        expect(json['hmac'], equals(base64.encode(hmac)));
      });
      
      test('should serialize minimal secure share to JSON', () {
        const share = SecureShare(
          x: 50,
          y: 60,
          version: 2,
          threshold: 3,
          totalShares: 6,
        );
        
        final json = share.toJson();
        
        expect(json['x'], equals(50));
        expect(json['y'], equals(60));
        expect(json['version'], equals(2));
        expect(json['threshold'], equals(3));
        expect(json['totalShares'], equals(6));
        expect(json.containsKey('identifier'), isFalse);
        expect(json.containsKey('hmac'), isFalse);
      });
      
      test('should deserialize from JSON correctly', () {
        final hmac = Uint8List.fromList(List.generate(32, (i) => i + 50));
        final json = {
          'x': 70,
          'y': 80,
          'version': 1,
          'threshold': 5,
          'totalShares': 8,
          'identifier': 'json-test',
          'hmac': base64.encode(hmac),
        };
        
        final share = SecureShare.fromJson(json);
        
        expect(share.x, equals(70));
        expect(share.y, equals(80));
        expect(share.version, equals(1));
        expect(share.threshold, equals(5));
        expect(share.totalShares, equals(8));
        expect(share.identifier, equals('json-test'));
        expect(share.hmac, equals(hmac));
      });
      
      test('should roundtrip through JSON', () {
        final hmac = Uint8List.fromList(List.generate(32, (i) => i + 77));
        final original = SecureShare(
          x: 90,
          y: 100,
          version: 3,
          threshold: 6,
          totalShares: 10,
          identifier: 'roundtrip-test',
          hmac: hmac,
          metadata: {'extra': 'data'},
        );
        
        final json = original.toJson();
        final restored = SecureShare.fromJson(json);
        
        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.version, equals(original.version));
        expect(restored.threshold, equals(original.threshold));
        expect(restored.totalShares, equals(original.totalShares));
        expect(restored.identifier, equals(original.identifier));
        expect(restored.hmac, equals(original.hmac));
        expect(restored.metadata, equals(original.metadata));
      });
    });
  });
  
  group('ShareSet', () {
    group('Basic ShareSet Operations', () {
      test('should create share set with shares and metadata', () {
        final shares = [
          Share(x: 1, y: 10),
          Share(x: 2, y: 20),
          Share(x: 3, y: 30),
        ];
        
        final metadata = ShareSetMetadata(
          id: 'test-set',
          shareIndex: 1,
          threshold: 3,
          totalShares: 5,
          secretLength: 10,
          createdAt: DateTime(2024, 1, 1),
        );
        
        final shareSet = ShareSet(shares: shares, metadata: metadata);
        
        expect(shareSet.shares, equals(shares));
        expect(shareSet.metadata, equals(metadata));
      });
      
      test('should get share at specific index', () {
        final shares = [
          Share(x: 1, y: 100),
          Share(x: 2, y: 200),
        ];
        
        final metadata = ShareSetMetadata(
          id: 'index-test',
          shareIndex: 1,
          threshold: 2,
          totalShares: 3,
          secretLength: 5,
          createdAt: DateTime.now(),
        );
        
        final shareSet = ShareSet(shares: shares, metadata: metadata);
        
        expect(shareSet.getShareAt(0), equals(shares[0]));
        expect(shareSet.getShareAt(1), equals(shares[1]));
        expect(shareSet.getShareAt(2), isNull);
        expect(shareSet.getShareAt(-1), isNull);
      });
    });
    
    group('ShareSet Serialization', () {
      test('should serialize to JSON', () {
        final shares = [Share(x: 5, y: 50), Share(x: 6, y: 60)];
        final metadata = ShareSetMetadata(
          id: 'serialize-test',
          shareIndex: 2,
          threshold: 3,
          totalShares: 4,
          secretLength: 8,
          createdAt: DateTime(2024, 6, 15, 10, 30),
          description: 'Test description',
        );
        
        final shareSet = ShareSet(shares: shares, metadata: metadata);
        final json = shareSet.toJson();
        
        expect(json['shares'], hasLength(2));
        expect(json['shares'][0]['x'], equals(5));
        expect(json['shares'][0]['y'], equals(50));
        expect(json['metadata']['id'], equals('serialize-test'));
      });
      
      test('should deserialize from JSON', () {
        final json = {
          'shares': [
            {'x': 10, 'y': 110},
            {'x': 11, 'y': 120},
          ],
          'metadata': {
            'id': 'deserialize-test',
            'shareIndex': 3,
            'threshold': 4,
            'totalShares': 6,
            'secretLength': 12,
            'createdAt': '2024-01-15T12:00:00.000',
          },
        };
        
        final shareSet = ShareSet.fromJson(json);
        
        expect(shareSet.shares, hasLength(2));
        expect(shareSet.shares[0].x, equals(10));
        expect(shareSet.shares[1].y, equals(120));
        expect(shareSet.metadata.id, equals('deserialize-test'));
        expect(shareSet.metadata.shareIndex, equals(3));
      });
      
      test('should roundtrip through Base64', () {
        final shares = [Share(x: 15, y: 150), Share(x: 16, y: 160)];
        final metadata = ShareSetMetadata(
          id: 'base64-test',
          shareIndex: 1,
          threshold: 2,
          totalShares: 3,
          secretLength: 20,
          createdAt: DateTime(2024, 3, 1),
        );
        
        final original = ShareSet(shares: shares, metadata: metadata);
        final base64 = original.toBase64();
        final restored = ShareSet.fromBase64(base64);
        
        expect(restored.shares, hasLength(original.shares.length));
        for (int i = 0; i < original.shares.length; i++) {
          expect(restored.shares[i], equals(original.shares[i]));
        }
        expect(restored.metadata.id, equals(original.metadata.id));
      });
    });
  });
  
  group('ShareSetMetadata', () {
    test('should create metadata with all fields', () {
      final createdAt = DateTime(2024, 8, 18, 14, 30);
      final metadata = ShareSetMetadata(
        id: 'full-metadata',
        shareIndex: 2,
        threshold: 4,
        totalShares: 7,
        secretLength: 32,
        createdAt: createdAt,
        description: 'Complete metadata test',
      );
      
      expect(metadata.id, equals('full-metadata'));
      expect(metadata.shareIndex, equals(2));
      expect(metadata.threshold, equals(4));
      expect(metadata.totalShares, equals(7));
      expect(metadata.secretLength, equals(32));
      expect(metadata.createdAt, equals(createdAt));
      expect(metadata.description, equals('Complete metadata test'));
    });
    
    test('should serialize to JSON with optional fields', () {
      final metadata = ShareSetMetadata(
        id: 'json-metadata',
        shareIndex: 1,
        threshold: 3,
        totalShares: 5,
        secretLength: 16,
        createdAt: DateTime(2024, 12, 25, 9, 15),
        description: 'JSON test',
      );
      
      final json = metadata.toJson();
      
      expect(json['id'], equals('json-metadata'));
      expect(json['shareIndex'], equals(1));
      expect(json['threshold'], equals(3));
      expect(json['totalShares'], equals(5));
      expect(json['secretLength'], equals(16));
      expect(json['createdAt'], equals('2024-12-25T09:15:00.000'));
      expect(json['description'], equals('JSON test'));
    });
    
    test('should serialize to JSON without optional fields', () {
      final metadata = ShareSetMetadata(
        id: 'minimal-metadata',
        shareIndex: 3,
        threshold: 2,
        totalShares: 4,
        secretLength: 8,
        createdAt: DateTime(2024, 5, 10),
      );
      
      final json = metadata.toJson();
      
      expect(json['id'], equals('minimal-metadata'));
      expect(json.containsKey('description'), isFalse);
    });
    
    test('should deserialize from JSON', () {
      final json = {
        'id': 'deserialize-metadata',
        'shareIndex': 4,
        'threshold': 5,
        'totalShares': 8,
        'secretLength': 24,
        'createdAt': '2024-07-04T16:45:30.000',
        'description': 'Deserialization test',
      };
      
      final metadata = ShareSetMetadata.fromJson(json);
      
      expect(metadata.id, equals('deserialize-metadata'));
      expect(metadata.shareIndex, equals(4));
      expect(metadata.threshold, equals(5));
      expect(metadata.totalShares, equals(8));
      expect(metadata.secretLength, equals(24));
      expect(metadata.createdAt, equals(DateTime(2024, 7, 4, 16, 45, 30)));
      expect(metadata.description, equals('Deserialization test'));
    });
  });
  
  group('ShareGenerator', () {
    group('Single Byte Share Generation', () {
      test('should generate correct number of shares', () {
        const secret = 100;
        const threshold = 3;
        const totalShares = 5;
        
        final shares = ShareGenerator.generateShares(
          secret: secret,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        expect(shares, hasLength(totalShares));
        
        // All shares should be valid
        for (final share in shares) {
          expect(share.isValid, isTrue);
        }
        
        // All x values should be unique and non-zero
        final xValues = shares.map((s) => s.x).toList();
        expect(xValues.toSet(), hasLength(totalShares));
        expect(xValues.every((x) => x > 0), isTrue);
      });
      
      test('should throw when totalShares < threshold', () {
        expect(
          () => ShareGenerator.generateShares(
            secret: 50,
            threshold: 5,
            totalShares: 3,
          ),
          throwsArgumentError,
        );
      });
      
      test('should handle minimum case (threshold = totalShares)', () {
        const secret = 200;
        const threshold = 2;
        
        final shares = ShareGenerator.generateShares(
          secret: secret,
          threshold: threshold,
          totalShares: threshold,
        );
        
        expect(shares, hasLength(threshold));
        
        // Should be able to reconstruct secret
        final xValues = shares.map((s) => s.x).toList();
        final yValues = shares.map((s) => s.y).toList();
        
        // Add secret point (0, secret) to make threshold points
        xValues.insert(0, 0);
        yValues.insert(0, secret);
        
        // Remove one share to have exactly threshold points
        xValues.removeLast();
        yValues.removeLast();
        
        final reconstructed = GF256.lagrangeInterpolate(xValues, yValues);
        expect(reconstructed, equals(secret));
      });
    });
    
    group('Secure Share Generation', () {
      test('should generate secure shares with metadata', () {
        const secret = 150;
        const threshold = 4;
        const totalShares = 6;
        const identifier = 'secure-test';
        const version = 2;
        
        final secureShares = ShareGenerator.generateSecureShares(
          secret: secret,
          threshold: threshold,
          totalShares: totalShares,
          identifier: identifier,
          version: version,
        );
        
        expect(secureShares, hasLength(totalShares));
        
        for (final share in secureShares) {
          expect(share.version, equals(version));
          expect(share.threshold, equals(threshold));
          expect(share.totalShares, equals(totalShares));
          expect(share.identifier, equals(identifier));
          expect(share.hasValidHmac, isTrue);
          expect(share.isValid, isTrue);
        }
      });
      
      test('should generate secure shares with default version', () {
        const secret = 75;
        const threshold = 2;
        const totalShares = 3;
        
        final secureShares = ShareGenerator.generateSecureShares(
          secret: secret,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        expect(secureShares, hasLength(totalShares));
        
        for (final share in secureShares) {
          expect(share.version, equals(1)); // Default version
          expect(share.threshold, equals(threshold));
          expect(share.totalShares, equals(totalShares));
          expect(share.identifier, isNull);
          expect(share.hasValidHmac, isTrue);
        }
      });
    });
    
    group('Multi-Byte Share Generation', () {
      test('should generate share sets for byte array', () {
        final secretBytes = Uint8List.fromList([10, 20, 30, 40]);
        const threshold = 3;
        const totalShares = 5;
        const description = 'Multi-byte test';
        
        final shareSets = ShareGenerator.generateShareSets(
          secretBytes: secretBytes,
          threshold: threshold,
          totalShares: totalShares,
          description: description,
        );
        
        expect(shareSets, hasLength(totalShares));
        
        // Each share set should have shares for each byte
        for (final shareSet in shareSets) {
          expect(shareSet.shares, hasLength(secretBytes.length));
          expect(shareSet.metadata.threshold, equals(threshold));
          expect(shareSet.metadata.totalShares, equals(totalShares));
          expect(shareSet.metadata.secretLength, equals(secretBytes.length));
          expect(shareSet.metadata.description, equals(description));
          
          // All shares in the set should have the same x coordinate
          final x = shareSet.shares[0].x;
          for (final share in shareSet.shares) {
            expect(share.x, equals(x));
            expect(share.isValid, isTrue);
          }
        }
        
        // All share sets should have different x coordinates
        final xValues = shareSets.map((s) => s.shares[0].x).toList();
        expect(xValues.toSet(), hasLength(totalShares));
      });
      
      test('should throw for empty secret bytes', () {
        final emptyBytes = Uint8List(0);
        
        expect(
          () => ShareGenerator.generateShareSets(
            secretBytes: emptyBytes,
            threshold: 2,
            totalShares: 3,
          ),
          throwsArgumentError,
        );
      });
      
      test('should handle single byte array', () {
        final singleByte = Uint8List.fromList([255]);
        const threshold = 2;
        const totalShares = 3;
        
        final shareSets = ShareGenerator.generateShareSets(
          secretBytes: singleByte,
          threshold: threshold,
          totalShares: totalShares,
        );
        
        expect(shareSets, hasLength(totalShares));
        
        for (final shareSet in shareSets) {
          expect(shareSet.shares, hasLength(1));
          expect(shareSet.metadata.secretLength, equals(1));
        }
      });
      
      test('should generate unique share set IDs', () {
        final secretBytes = Uint8List.fromList([1, 2]);
        
        final shareSets1 = ShareGenerator.generateShareSets(
          secretBytes: secretBytes,
          threshold: 2,
          totalShares: 2,
        );
        
        final shareSets2 = ShareGenerator.generateShareSets(
          secretBytes: secretBytes,
          threshold: 2,
          totalShares: 2,
        );
        
        expect(shareSets1[0].metadata.id, isNot(equals(shareSets2[0].metadata.id)));
      });
    });
  });
}