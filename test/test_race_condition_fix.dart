import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Test the updated race condition fix with longer delays
void main() {
  group('Updated Race Condition Fix Tests', () {
    test('Simulate CreateSecretScreen flow with validation', () async {
      final provider = SecretProvider();
      
      print('\n=== TESTING UPDATED FIX ===');
      
      // Step 1: Create secret (like CreateSecretScreen does)
      print('1. Creating secret...');
      final success = await provider.createSecret(
        secretName: 'Test Secret',
        secret: 'Hello World',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isTrue);
      print('   createSecret returned: $success');
      
      // Step 2: Wait 150ms (like the updated CreateSecretScreen)
      print('2. Waiting 150ms for state synchronization...');
      await Future.delayed(const Duration(milliseconds: 150));
      
      // Step 3: Validate isSecretReady (like CreateSecretScreen does)
      print('3. Checking isSecretReady...');
      final isReady = provider.isSecretReady;
      print('   isSecretReady: $isReady');
      expect(isReady, isTrue);
      
      // Step 4: Test getDistributionPackages (like CreateSecretScreen does)
      print('4. Testing getDistributionPackages...');
      final packages = provider.getDistributionPackages();
      print('   Packages available: ${packages.length}');
      expect(packages.length, equals(3));
      
      // Step 5: Simulate navigation would happen now
      print('5. All validations passed - navigation would occur');
      
      // Step 6: Test ShareDistributionScreen access pattern
      print('6. Testing ShareDistributionScreen access...');
      final sharePackages = provider.getDistributionPackages();
      print('   ShareDistributionScreen would see: ${sharePackages.length} packages');
      expect(sharePackages.length, equals(3));
      
      print('=== FIX VALIDATION SUCCESSFUL ===\n');
    });

    test('Test multiple rapid operations', () async {
      print('\n=== TESTING MULTIPLE OPERATIONS ===');
      
      final provider = SecretProvider();
      
      // Test multiple create operations
      for (int i = 1; i <= 3; i++) {
        print('Operation $i:');
        
        final success = await provider.createSecret(
          secretName: 'Test Secret $i',
          secret: 'Hello World $i',
          threshold: 2,
          totalShares: 3,
        );
        
        print('  createSecret: $success');
        
        // Apply the same delay as CreateSecretScreen
        await Future.delayed(const Duration(milliseconds: 150));
        
        final isReady = provider.isSecretReady;
        final packages = provider.getDistributionPackages();
        
        print('  isSecretReady: $isReady');
        print('  packages: ${packages.length}');
        
        expect(success, isTrue);
        expect(isReady, isTrue);
        expect(packages.length, equals(3));
        
        // Clear results between operations
        provider.clearResults();
        print('  cleared results\n');
      }
      
      print('=== MULTIPLE OPERATIONS SUCCESSFUL ===\n');
    });
  });
}