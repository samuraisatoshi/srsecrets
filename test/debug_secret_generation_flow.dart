import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';
import 'package:srsecrets/domains/crypto/shamir/shamir_secret_sharing.dart';

void main() {
  group('Debug Secret Generation Flow', () {
    test('Detailed analysis of secret generation flow', () async {
      final provider = SecretProvider();
      
      print('\n=== DEBUGGING SECRET GENERATION FLOW ===');
      
      // Step 1: Check initial state
      print('1. Initial state:');
      print('   - lastResult: ${provider.lastResult}');
      print('   - errorMessage: ${provider.errorMessage}');
      print('   - isLoading: ${provider.isLoading}');
      
      // Step 2: Create a secret
      print('\n2. Creating secret...');
      final success = await provider.createSecret(
        secretName: 'Debug Test Secret',
        secret: 'This is a test secret for debugging',
        threshold: 2,
        totalShares: 3,
      );
      
      print('   - Success: $success');
      print('   - lastResult: ${provider.lastResult}');
      print('   - errorMessage: ${provider.errorMessage}');
      print('   - isLoading: ${provider.isLoading}');
      
      if (provider.lastResult != null) {
        print('   - shareSets length: ${provider.lastResult!.shareSets.length}');
        print('   - threshold: ${provider.lastResult!.threshold}');
        print('   - totalShares: ${provider.lastResult!.totalShares}');
      }
      
      // Step 3: Try to get distribution packages
      print('\n3. Getting distribution packages...');
      final packages = provider.getDistributionPackages();
      print('   - Packages length: ${packages.length}');
      
      if (packages.isEmpty && provider.lastResult != null) {
        print('   - WARNING: lastResult exists but packages are empty');
        print('   - Calling createDistributionPackages directly...');
        try {
          final directPackages = provider.lastResult!.createDistributionPackages();
          print('   - Direct packages length: ${directPackages.length}');
        } catch (e) {
          print('   - Error calling createDistributionPackages: $e');
        }
      }
      
      // Step 4: Verify the actual ShamirSecretSharing directly
      print('\n4. Testing ShamirSecretSharing directly...');
      try {
        final result = ShamirSecretSharing.splitString(
          secret: 'This is a test secret for debugging',
          threshold: 2,
          shares: 3,
        );
        print('   - Direct result shareSets length: ${result.shareSets.length}');
        
        final directPackages = result.createDistributionPackages();
        print('   - Direct packages length: ${directPackages.length}');
        
        for (int i = 0; i < directPackages.length; i++) {
          final package = directPackages[i];
          print('   - Package $i: participant=${package.participantNumber}, threshold=${package.threshold}');
        }
      } catch (e) {
        print('   - Error in direct ShamirSecretSharing: $e');
      }
      
      print('\n=== END DEBUGGING ===\n');
      
      // Standard assertions
      expect(success, isTrue);
      expect(provider.lastResult, isNotNull);
      expect(packages, isNotEmpty);
    });
  });
}