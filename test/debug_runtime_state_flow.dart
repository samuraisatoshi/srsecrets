import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';

/// Debug test to reproduce the exact runtime scenario that causes _lastResult to be null
void main() {
  group('Runtime State Flow Analysis', () {
    test('Reproduce the exact runtime scenario', () async {
      final provider = SecretProvider();
      
      print('\n=== REPRODUCING RUNTIME SCENARIO ===');
      
      // Step 1: Simulate the CreateSecretScreen.createSecret call
      print('1. Simulating CreateSecretScreen._createSecret() flow...');
      
      // Check initial state
      print('   Initial state: lastResult=${provider.lastResult}');
      
      // Call createSecret (this is what CreateSecretScreen does)
      print('   Calling createSecret...');
      final success = await provider.createSecret(
        secretName: 'Test Secret',
        secret: 'This is my secret',
        threshold: 3,
        totalShares: 5,
      );
      
      print('   createSecret returned: $success');
      print('   After createSecret: lastResult=${provider.lastResult}');
      
      // Check isSecretReady (this is what CreateSecretScreen checks)
      print('   Checking isSecretReady: ${provider.isSecretReady}');
      
      // Step 2: Simulate the ShareDistributionScreen accessing the state
      print('\n2. Simulating ShareDistributionScreen build...');
      
      // This is exactly what ShareDistributionScreen does in line 22
      final packages = provider.getDistributionPackages();
      print('   getDistributionPackages returned: ${packages.length} packages');
      
      // Step 3: Test potential race conditions
      print('\n3. Testing for potential race conditions...');
      
      // Simulate rapid state access (potential race condition)
      provider.clearResults(); // This might be called somewhere
      print('   After clearResults: lastResult=${provider.lastResult}');
      
      final packagesAfterClear = provider.getDistributionPackages();
      print('   getDistributionPackages after clear: ${packagesAfterClear.length} packages');
      
      // Step 4: Test multiple sequential operations
      print('\n4. Testing sequential operations...');
      
      // Create another secret
      await provider.createSecret(
        secretName: 'Second Secret',
        secret: 'Another secret',
        threshold: 2,
        totalShares: 4,
      );
      
      print('   After second createSecret: lastResult=${provider.lastResult}');
      
      // Immediate access
      final immediatePackages = provider.getDistributionPackages();
      print('   Immediate packages: ${immediatePackages.length}');
      
      // Step 5: Test error scenarios
      print('\n5. Testing error scenarios...');
      
      // Try with invalid parameters to potentially corrupt state
      try {
        await provider.createSecret(
          secretName: '',
          secret: '',
          threshold: 1,
          totalShares: 2,
        );
      } catch (e) {
        print('   Expected error caught: $e');
      }
      
      print('   After error scenario: lastResult=${provider.lastResult}');
      final packagesAfterError = provider.getDistributionPackages();
      print('   Packages after error: ${packagesAfterError.length}');
      
      print('\n=== END RUNTIME SCENARIO ===\n');
      
      // Key insight: The issue might be in the timing or state clearing
      expect(success, isTrue, reason: 'Secret creation should succeed');
    });
    
    test('Analyze provider state lifecycle', () async {
      final provider = SecretProvider();
      
      print('\n=== PROVIDER STATE LIFECYCLE ANALYSIS ===');
      
      // Track state changes through the full lifecycle
      int notificationCount = 0;
      provider.addListener(() {
        notificationCount++;
        print('   Notification #$notificationCount: lastResult=${provider.lastResult != null ? "present" : "null"}');
      });
      
      print('1. Creating secret with listener attached...');
      await provider.createSecret(
        secretName: 'Lifecycle Test',
        secret: 'Test secret',
        threshold: 2,
        totalShares: 3,
      );
      
      print('   Total notifications received: $notificationCount');
      print('   Final state: lastResult=${provider.lastResult != null ? "present" : "null"}');
      
      // Test getDistributionPackages multiple times
      print('\n2. Multiple calls to getDistributionPackages...');
      for (int i = 0; i < 3; i++) {
        final packages = provider.getDistributionPackages();
        print('   Call $i: ${packages.length} packages');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('\n=== END LIFECYCLE ANALYSIS ===\n');
    });
  });
}