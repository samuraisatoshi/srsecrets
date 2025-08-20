import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Test the synchronous fix - no more async delays!
void main() {
  group('Synchronous Fix Tests', () {
    test('createSecret should work synchronously', () {
      final provider = SecretProvider();
      
      print('\n=== TESTING SYNCHRONOUS APPROACH ===');
      
      // This should work immediately, no await needed
      final success = provider.createSecret(
        secretName: 'Test Secret',
        secret: 'Hello World',
        threshold: 2,
        totalShares: 3,
      );
      
      print('Success: $success');
      print('isSecretReady: ${provider.isSecretReady}');
      print('lastResult: ${provider.lastResult != null}');
      
      expect(success, isTrue);
      expect(provider.isSecretReady, isTrue);
      expect(provider.lastResult, isNotNull);
      
      // Packages should be immediately available
      final packages = provider.getDistributionPackages();
      print('Packages: ${packages.length}');
      expect(packages.length, equals(3));
      
      print('=== SYNCHRONOUS APPROACH WORKS ===\n');
    });

    test('Reproduce the exact error scenario', () {
      final provider = SecretProvider();
      
      print('\n=== REPRODUCING ERROR SCENARIO ===');
      
      // Step 1: Try to get packages when no secret exists (should warn but not crash)
      print('1. Getting packages with no secret...');
      final emptyPackages = provider.getDistributionPackages();
      print('   Packages: ${emptyPackages.length}');
      expect(emptyPackages.length, equals(0));
      
      // Step 2: Create secret
      print('2. Creating secret...');
      final success = provider.createSecret(
        secretName: 'Test',
        secret: 'Hello',
        threshold: 2,
        totalShares: 3,
      );
      print('   Success: $success');
      
      // Step 3: Immediately get packages (this is what ShareDistributionScreen does)
      print('3. Immediately getting packages...');
      final packages = provider.getDistributionPackages();
      print('   Packages: ${packages.length}');
      
      expect(success, isTrue);
      expect(packages.length, equals(3));
      print('   ✅ No more race condition!');
      
      print('=== ERROR SCENARIO FIXED ===\n');
    });

    test('Test the exact CreateSecretScreen -> ShareDistributionScreen flow', () {
      final provider = SecretProvider();
      
      print('\n=== TESTING UI FLOW ===');
      
      // Simulate CreateSecretScreen._createSecret()
      print('1. CreateSecretScreen: calling createSecret()...');
      final success = provider.createSecret(
        secretName: 'UI Test',
        secret: 'UI Secret',
        threshold: 2,
        totalShares: 3,
      );
      
      print('   createSecret returned: $success');
      
      // Simulate CreateSecretScreen validation
      print('2. CreateSecretScreen: checking isSecretReady...');
      final isReady = provider.isSecretReady;
      print('   isSecretReady: $isReady');
      
      if (success && isReady) {
        print('3. CreateSecretScreen: navigation would occur');
        
        // Simulate ShareDistributionScreen.build()
        print('4. ShareDistributionScreen: building with context.watch<SecretProvider>()...');
        print('5. ShareDistributionScreen: calling getDistributionPackages()...');
        
        final packages = provider.getDistributionPackages();
        print('   Packages available: ${packages.length}');
        
        expect(packages.length, equals(3));
        expect(packages.isEmpty, isFalse);
        
        print('   ✅ ShareDistributionScreen shows packages correctly!');
      } else {
        fail('CreateSecretScreen validation failed');
      }
      
      print('=== UI FLOW WORKS PERFECTLY ===\n');
    });
  });
}