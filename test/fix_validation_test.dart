import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Test to validate the fix for the _lastResult null issue and race conditions
void main() {
  group('Secret Generation Race Condition Fix Tests', () {
    test('Verify state management fix prevents null errors', () async {
      final provider = SecretProvider();
      
      print('\n=== VALIDATING FIX ===');
      
      // Step 1: Normal flow
      print('1. Normal secret creation and access...');
      final success = await provider.createSecret(
        secretName: 'Test Secret',
        secret: 'My secret content',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isTrue);
      expect(provider.lastResult, isNotNull);
      
      final packages = provider.getDistributionPackages();
      print('   Initial packages: ${packages.length}');
      expect(packages.length, equals(3));
      
      // Step 2: Test safe distribution packages getter
      print('2. Testing safe distribution packages...');
      final safePackages = provider.getSafeDistributionPackages();
      print('   Safe packages: ${safePackages.length}');
      expect(safePackages.length, equals(3));
      
      // Step 3: Clear results and test safe getter
      print('3. Testing state after clearResults...');
      provider.clearResults();
      
      // Original method should return empty
      final packagesAfterClear = provider.getDistributionPackages();
      print('   Packages after clear: ${packagesAfterClear.length}');
      expect(packagesAfterClear.length, equals(0));
      
      // Safe method should also return empty (as expected)
      final safePackagesAfterClear = provider.getSafeDistributionPackages();
      print('   Safe packages after clear: ${safePackagesAfterClear.length}');
      expect(safePackagesAfterClear.length, equals(0));
      
      print('\n=== FIX VALIDATED ===\n');
    });
    
    test('Verify rapid state access scenarios', () async {
      final provider = SecretProvider();
      
      print('\n=== RAPID STATE ACCESS TEST ===');
      
      // Create secret
      await provider.createSecret(
        secretName: 'Rapid Test',
        secret: 'Test content',
        threshold: 2,
        totalShares: 4,
      );
      
      // Rapid access simulation (like UI rebuilds)
      final results = <int>[];
      for (int i = 0; i < 10; i++) {
        final packages = provider.getDistributionPackages();
        results.add(packages.length);
        
        // Simulate some async operations
        if (i == 5) {
          provider.clearResults();
        }
      }
      
      print('   Access results: $results');
      
      // Verify that we get consistent results before clearing
      expect(results.take(5).every((count) => count == 4), isTrue,
          reason: 'Should get 4 packages before clearing');
      
      // Verify that we get 0 packages after clearing
      // Note: First call after clearing still returns 4 due to cached state
      expect(results.skip(6).every((count) => count == 0), isTrue,
          reason: 'Should get 0 packages after clearing (except first cached call)');
      
      print('\n=== RAPID ACCESS TEST PASSED ===\n');
    });
    
    test('Verify error handling maintains state integrity', () async {
      final provider = SecretProvider();
      
      print('\n=== ERROR HANDLING TEST ===');
      
      // Create a valid secret
      await provider.createSecret(
        secretName: 'Valid Secret',
        secret: 'Valid content',
        threshold: 2,
        totalShares: 3,
      );
      
      final validPackages = provider.getDistributionPackages();
      print('   Valid packages: ${validPackages.length}');
      expect(validPackages.length, equals(3));
      
      // Try to create an invalid secret (should fail but not corrupt state)
      final invalidResult = await provider.createSecret(
        secretName: '',  // Invalid empty name
        secret: '',      // Invalid empty secret
        threshold: 1,    // Invalid threshold
        totalShares: 2,
      );
      
      print('   Invalid secret result: $invalidResult');
      expect(invalidResult, isFalse);
      
      // State should still be valid (the previous valid secret)
      final packagesAfterError = provider.getDistributionPackages();
      print('   Packages after error: ${packagesAfterError.length}');
      
      // The provider should maintain the last valid result
      expect(packagesAfterError.length, equals(3),
          reason: 'Should maintain last valid state after error');
      
      print('\n=== ERROR HANDLING TEST PASSED ===\n');
    });
  });
}