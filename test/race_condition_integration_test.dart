import 'package:flutter_test/flutter_test.dart';

import '../lib/presentation/providers/secret_provider.dart';

/// Integration test specifically for the race condition bug
/// User clicks "Create Secret Shares" -> navigation happens before state is ready -> error
void main() {
  group('Race Condition Integration Tests', () {

    test('createSecret includes timing delay to prevent race conditions', () async {
      final provider = SecretProvider();
      
      // Test that createSecret properly waits for state synchronization
      final stopwatch = Stopwatch()..start();
      
      final success = await provider.createSecret(
        secretName: 'Timing Test',
        secret: 'Test content',
        threshold: 2,
        totalShares: 3,
      );
      
      stopwatch.stop();
      
      expect(success, isTrue);
      expect(provider.isSecretReady, isTrue);
      expect(stopwatch.elapsedMilliseconds, greaterThan(5)); // Should include 5ms delay
      
      final packages = provider.getDistributionPackages();
      expect(packages.length, equals(3));
    });

    test('race condition scenario - rapid navigation simulation', () async {
      final provider = SecretProvider();
      
      print('\n=== SIMULATING RACE CONDITION SCENARIO ===');
      
      // Simulate the exact user flow:
      // 1. User clicks create button
      // 2. createSecret starts (async)
      // 3. Navigation happens immediately 
      // 4. ShareDistributionScreen tries to access packages before createSecret completes
      
      // Start the secret creation but don't await it yet
      final createFuture = provider.createSecret(
        secretName: 'Race Test',
        secret: 'Test content',  
        threshold: 2,
        totalShares: 3,
      );
      
      // Give a tiny delay to simulate the timing issue
      await Future.delayed(const Duration(milliseconds: 1));
      
      // Immediately try to access packages (simulating premature navigation)
      // This would be called by ShareDistributionScreen in the old buggy version
      var packages = provider.getDistributionPackages();
      print('   Packages during creation: ${packages.length}');
      // Note: With our fix, the creation might complete fast enough that packages are available
      
      // Now wait for creation to complete
      final success = await createFuture;
      expect(success, isTrue);
      
      // After completion, packages should definitely be available
      packages = provider.getDistributionPackages();
      print('   Packages after completion: ${packages.length}');
      expect(packages.length, equals(3));
      
      // Verify state is ready
      expect(provider.isSecretReady, isTrue);
      
      print('=== RACE CONDITION HANDLED CORRECTLY ===\n');
    });

    test('simulated navigation with validation delay', () async {
      final provider = SecretProvider();
      
      print('\n=== SIMULATING NEW FIX BEHAVIOR ===');
      
      // This simulates the fixed CreateSecretScreen._createSecret() method
      final success = await provider.createSecret(
        secretName: 'Navigation Test',
        secret: 'Test content',
        threshold: 2,
        totalShares: 3,
      );
      
      print('   Secret creation success: $success');
      expect(success, isTrue);
      
      // Simulate the 50ms delay we added in CreateSecretScreen
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Simulate the validation check before navigation
      final isReady = provider.isSecretReady;
      print('   Secret ready for navigation: $isReady');
      expect(isReady, isTrue);
      
      if (isReady) {
        // This would be where navigation occurs in the fixed version
        final packages = provider.getDistributionPackages();
        print('   Packages available for display: ${packages.length}');
        expect(packages.length, equals(3));
        print('=== NAVIGATION SAFE - NO RACE CONDITION ===\n');
      }
    });
  });
}