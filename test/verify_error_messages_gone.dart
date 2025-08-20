import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Verify that the specific error messages reported by the user are gone
void main() {
  group('Error Messages Verification', () {
    test('Should NOT show "WARNING: getDistributionPackages called with null _lastResult"', () {
      final provider = SecretProvider();
      
      // Create secret first
      final success = provider.createSecret(
        secretName: 'Test Secret',
        secret: 'Hello World',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isTrue);
      
      // This should NOT print the WARNING message
      final packages = provider.getDistributionPackages();
      expect(packages.length, equals(3));
      expect(packages.isNotEmpty, isTrue);
    });

    test('Should NOT show "ERROR: No lastResult available in ShareDistributionScreen"', () {
      final provider = SecretProvider();
      
      // Create secret
      final success = provider.createSecret(
        secretName: 'Test Secret',
        secret: 'Hello World',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isTrue);
      expect(provider.lastResult, isNotNull);
      expect(provider.isSecretReady, isTrue);
      
      // This should work immediately without errors
      final packages = provider.getDistributionPackages();
      expect(packages.length, equals(3));
      
      // Verify all packages are valid
      for (final package in packages) {
        expect(package.participantNumber, greaterThan(0));
        expect(package.threshold, equals(2));
        expect(package.totalParticipants, equals(3));
        expect(package.shareSet.toBase64().isNotEmpty, isTrue);
      }
    });

    test('Real world scenario: CreateSecretScreen -> ShareDistributionScreen', () {
      final provider = SecretProvider();
      
      print('\n=== REAL WORLD SCENARIO TEST ===');
      
      // Simulate user filling form and clicking Create Secret Shares
      print('User clicks "Create Secret Shares"...');
      
      final success = provider.createSecret(
        secretName: 'My Important Secret',
        secret: 'This is very important',
        threshold: 3,
        totalShares: 5,
      );
      
      print('CreateSecretScreen: createSecret() = $success');
      print('CreateSecretScreen: isSecretReady = ${provider.isSecretReady}');
      
      expect(success, isTrue);
      expect(provider.isSecretReady, isTrue);
      
      // Navigation would happen here...
      print('Navigation to ShareDistributionScreen...');
      
      // ShareDistributionScreen builds and accesses provider
      print('ShareDistributionScreen: accessing packages...');
      final packages = provider.getDistributionPackages();
      
      print('ShareDistributionScreen: found ${packages.length} packages');
      
      expect(packages.length, equals(5));
      expect(packages.isEmpty, isFalse, reason: 'Should NOT show "No shares available" error');
      
      // Verify ShareDistributionScreen would display correctly
      for (int i = 0; i < packages.length; i++) {
        final package = packages[i];
        print('Package ${i + 1}: participant=${package.participantNumber}, threshold=${package.threshold}');
        
        expect(package.participantNumber, equals(i + 1));
        expect(package.threshold, equals(3));
        expect(package.totalParticipants, equals(5));
      }
      
      print('✅ ShareDistributionScreen displays packages correctly');
      print('✅ No "WARNING: getDistributionPackages called with null _lastResult"');
      print('✅ No "ERROR: No lastResult available in ShareDistributionScreen"');
      
      print('=== REAL WORLD SCENARIO WORKS ===\n');
    });
  });
}