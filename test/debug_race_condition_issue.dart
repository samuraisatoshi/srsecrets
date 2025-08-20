import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Debug test to reproduce the exact race condition issue
void main() {
  group('Debug Race Condition Issue', () {
    test('Reproduce the exact issue flow', () async {
      final provider = SecretProvider();
      
      print('\n=== REPRODUCING EXACT BUG ===');
      
      // Step 1: Start createSecret but check state immediately
      print('1. Starting createSecret...');
      final createFuture = provider.createSecret(
        secretName: 'Test',
        secret: 'Hello',
        threshold: 2,
        totalShares: 3,
      );
      
      // Step 2: Immediately check if ready (simulating navigation check)
      print('2. Checking isSecretReady immediately...');
      final isReadyBefore = provider.isSecretReady;
      print('   isSecretReady before completion: $isReadyBefore');
      
      // Step 3: Try to get packages (what ShareDistributionScreen does)
      print('3. Calling getDistributionPackages...');
      final packagesBefore = provider.getDistributionPackages();
      print('   Packages before completion: ${packagesBefore.length}');
      
      // Step 4: Now wait for completion
      print('4. Waiting for createSecret to complete...');
      final success = await createFuture;
      print('   createSecret success: $success');
      
      // Step 5: Check state after completion
      final isReadyAfter = provider.isSecretReady;
      final packagesAfter = provider.getDistributionPackages();
      print('   isSecretReady after completion: $isReadyAfter');
      print('   Packages after completion: ${packagesAfter.length}');
      
      print('\n=== DIAGNOSIS ===');
      print('The issue is that isSecretReady returns false and getDistributionPackages returns empty');
      print('even after createSecret claims to be successful.');
      print('This suggests the validation or state setting is still not working properly.');
    });

    test('Debug the internal state during createSecret', () async {
      final provider = SecretProvider();
      
      print('\n=== INTERNAL STATE DEBUG ===');
      
      // Check initial state
      print('Initial state:');
      print('  lastResult: ${provider.lastResult}');
      print('  isSecretReady: ${provider.isSecretReady}');
      print('  errorMessage: ${provider.errorMessage}');
      
      // Call createSecret and inspect result
      final success = await provider.createSecret(
        secretName: 'Debug Test',
        secret: 'Debug secret content',
        threshold: 2,
        totalShares: 3,
      );
      
      print('\nAfter createSecret:');
      print('  success returned: $success');
      print('  lastResult: ${provider.lastResult}');
      print('  isSecretReady: ${provider.isSecretReady}');
      print('  errorMessage: ${provider.errorMessage}');
      
      if (provider.lastResult != null) {
        print('  lastResult.shareSets.length: ${provider.lastResult!.shareSets.length}');
        print('  lastResult.threshold: ${provider.lastResult!.threshold}');
        
        try {
          final testPackages = provider.lastResult!.createDistributionPackages();
          print('  Direct package creation: ${testPackages.length} packages');
        } catch (e) {
          print('  ERROR in direct package creation: $e');
        }
      }
      
      // Test the getDistributionPackages method
      try {
        final packages = provider.getDistributionPackages();
        print('  getDistributionPackages result: ${packages.length} packages');
      } catch (e) {
        print('  ERROR in getDistributionPackages: $e');
      }
    });
  });
}