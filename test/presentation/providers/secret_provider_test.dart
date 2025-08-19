import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';

void main() {
  group('SecretProvider', () {
    late SecretProvider provider;
    
    setUp(() {
      provider = SecretProvider();
    });
    
    group('Initial State', () {
      test('should have correct initial values', () {
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.secrets, isEmpty);
        expect(provider.lastResult, isNull);
        expect(provider.reconstructedSecret, isNull);
        expect(provider.isSecretReady, isFalse);
      });
    });
    
    group('Secret Creation', () {
      test('should create secret successfully with valid inputs', () async {
        final success = await provider.createSecret(
          secretName: 'Test Secret',
          secret: 'My test secret message',
          threshold: 3,
          totalShares: 5,
        );
        
        expect(success, isTrue);
        expect(provider.errorMessage, isNull);
        expect(provider.lastResult, isNotNull);
        expect(provider.isSecretReady, isTrue);
        expect(provider.secrets.length, equals(1));
        
        final secretInfo = provider.secrets.first;
        expect(secretInfo.name, equals('Test Secret'));
        expect(secretInfo.threshold, equals(3));
        expect(secretInfo.totalShares, equals(5));
        expect(secretInfo.type, equals('text'));
      });
      
      test('should fail with empty secret name', () async {
        final success = await provider.createSecret(
          secretName: '',
          secret: 'Valid secret',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(success, isFalse);
        expect(provider.errorMessage, contains('Secret name cannot be empty'));
        expect(provider.lastResult, isNull);
        expect(provider.isSecretReady, isFalse);
      });
      
      test('should fail with empty secret content', () async {
        final success = await provider.createSecret(
          secretName: 'Valid Name',
          secret: '',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(success, isFalse);
        expect(provider.errorMessage, contains('Secret cannot be empty'));
        expect(provider.lastResult, isNull);
        expect(provider.isSecretReady, isFalse);
      });
      
      test('should trim whitespace and validate properly', () async {
        final success = await provider.createSecret(
          secretName: '   ',
          secret: '   ',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(success, isFalse);
        expect(provider.isSecretReady, isFalse);
      });
      
      test('should clear previous state when creating new secret', () async {
        // Create first secret
        await provider.createSecret(
          secretName: 'First',
          secret: 'First secret',
          threshold: 2,
          totalShares: 3,
        );
        
        final firstResult = provider.lastResult;
        expect(firstResult, isNotNull);
        
        // Create second secret
        await provider.createSecret(
          secretName: 'Second',
          secret: 'Second secret',
          threshold: 3,
          totalShares: 5,
        );
        
        expect(provider.lastResult, isNot(equals(firstResult)));
        expect(provider.lastResult!.threshold, equals(3));
        expect(provider.lastResult!.totalShares, equals(5));
      });
    });
    
    group('Distribution Packages', () {
      test('should return empty list when no result available', () {
        final packages = provider.getDistributionPackages();
        expect(packages, isEmpty);
      });
      
      test('should return correct packages after secret creation', () async {
        await provider.createSecret(
          secretName: 'Test',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        
        final packages = provider.getDistributionPackages();
        expect(packages, hasLength(3));
        
        for (int i = 0; i < packages.length; i++) {
          final package = packages[i];
          expect(package.participantNumber, equals(i + 1));
          expect(package.threshold, equals(2));
          expect(package.totalParticipants, equals(3));
          expect(package.shareSet, isNotNull);
        }
      });
    });
    
    group('Secret Ready Validation', () {
      test('should return false when no result', () {
        expect(provider.isSecretReady, isFalse);
      });
      
      test('should return true when secret created successfully', () async {
        await provider.createSecret(
          secretName: 'Test',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(provider.isSecretReady, isTrue);
      });
      
      test('should return false after clearing results', () async {
        await provider.createSecret(
          secretName: 'Test',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(provider.isSecretReady, isTrue);
        
        provider.clearResults();
        expect(provider.isSecretReady, isFalse);
      });
    });
    
    group('Secret Reconstruction', () {
      test('should reconstruct secret from valid shares', () async {
        const originalSecret = 'My secret message to reconstruct';
        
        // Create secret first
        await provider.createSecret(
          secretName: 'Test',
          secret: originalSecret,
          threshold: 2,
          totalShares: 3,
        );
        
        // Get some shares
        final packages = provider.getDistributionPackages();
        final shareStrings = packages.take(2).map((p) => p.shareSet.toBase64()).toList();
        
        // Clear and reconstruct
        provider.clearResults();
        
        final success = await provider.reconstructSecret(shareStrings);
        
        expect(success, isTrue);
        expect(provider.reconstructedSecret, equals(originalSecret));
      });
      
      test('should fail with insufficient shares', () async {
        const originalSecret = 'My secret message';
        
        // Create secret with threshold 3
        await provider.createSecret(
          secretName: 'Test',
          secret: originalSecret,
          threshold: 3,
          totalShares: 5,
        );
        
        // Get only 2 shares (insufficient)
        final packages = provider.getDistributionPackages();
        final shareStrings = packages.take(2).map((p) => p.shareSet.toBase64()).toList();
        
        provider.clearResults();
        
        final success = await provider.reconstructSecret(shareStrings);
        
        expect(success, isFalse);
        expect(provider.errorMessage, isNotNull);
      });
    });
    
    group('Error Handling', () {
      test('should clear error message', () async {
        // Generate an error
        await provider.createSecret(
          secretName: '',
          secret: 'test',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(provider.errorMessage, isNotNull);
        
        provider.clearError();
        expect(provider.errorMessage, isNull);
      });
    });
    
    group('Secret Management', () {
      test('should remove secret by id', () async {
        await provider.createSecret(
          secretName: 'Test',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(provider.secrets, hasLength(1));
        final secretId = provider.secrets.first.id;
        
        provider.removeSecret(secretId);
        expect(provider.secrets, isEmpty);
      });
      
      test('should handle multiple secrets', () async {
        await provider.createSecret(
          secretName: 'First',
          secret: 'First secret',
          threshold: 2,
          totalShares: 3,
        );
        
        await provider.createSecret(
          secretName: 'Second',
          secret: 'Second secret',
          threshold: 3,
          totalShares: 5,
        );
        
        expect(provider.secrets, hasLength(2));
        expect(provider.secrets.first.name, equals('First'));
        expect(provider.secrets.last.name, equals('Second'));
      });
    });
  });
}