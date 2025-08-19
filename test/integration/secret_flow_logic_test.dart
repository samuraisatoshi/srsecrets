import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';

void main() {
  group('Secret Generation Logic Flow Tests', () {
    late SecretProvider provider;
    
    setUp(() {
      provider = SecretProvider();
    });
    
    test('Complete secret generation flow simulates user journey', () async {
      print('\n=== TESTING COMPLETE SECRET GENERATION FLOW ===');
      
      // Step 1: User fills out form and submits
      print('1. User creates secret...');
      final success = await provider.createSecret(
        secretName: 'My Important Secret',
        secret: 'This is a confidential message that needs to be shared securely',
        threshold: 3,
        totalShares: 5,
      );
      
      expect(success, isTrue, reason: 'Secret creation should succeed');
      expect(provider.errorMessage, isNull, reason: 'Should have no error message');
      expect(provider.isLoading, isFalse, reason: 'Should not be loading after completion');
      
      print('   ✓ Secret created successfully');
      print('   ✓ No errors reported');
      print('   ✓ Loading state cleared');
      
      // Step 2: Check that navigation conditions are met
      print('2. Checking navigation readiness...');
      expect(provider.isSecretReady, isTrue, reason: 'Secret should be ready for navigation');
      expect(provider.lastResult, isNotNull, reason: 'lastResult should exist');
      expect(provider.lastResult!.shareSets.isNotEmpty, isTrue, reason: 'Share sets should exist');
      
      print('   ✓ Secret is ready for navigation');
      print('   ✓ lastResult is available');
      print('   ✓ Share sets are populated (${provider.lastResult!.shareSets.length} sets)');
      
      // Step 3: Simulate navigation to distribution screen
      print('3. Simulating distribution screen load...');
      final packages = provider.getDistributionPackages();
      
      expect(packages, isNotEmpty, reason: 'Distribution packages should be available');
      expect(packages.length, equals(5), reason: 'Should have 5 packages for 5 total shares');
      
      print('   ✓ Distribution packages generated successfully');
      print('   ✓ Correct number of packages (${packages.length})');
      
      // Step 4: Validate package contents
      print('4. Validating package contents...');
      for (int i = 0; i < packages.length; i++) {
        final package = packages[i];
        expect(package.participantNumber, equals(i + 1), reason: 'Participant number should be sequential');
        expect(package.threshold, equals(3), reason: 'Package should have correct threshold');
        expect(package.totalParticipants, equals(5), reason: 'Package should have correct total participants');
        expect(package.shareSet, isNotNull, reason: 'Package should have share set');
        expect(package.shareSet.shares, isNotEmpty, reason: 'Share set should have shares');
        
        // Validate serialization works
        final json = package.toJson();
        expect(json, isNotNull, reason: 'Package should serialize to JSON');
        expect(json['participantNumber'], equals(i + 1));
        expect(json['threshold'], equals(3));
        expect(json['totalParticipants'], equals(5));
        
        final base64 = package.toBase64();
        expect(base64, isNotNull, reason: 'Package should serialize to base64');
        expect(base64.isNotEmpty, isTrue, reason: 'Base64 should not be empty');
      }
      
      print('   ✓ All packages validated successfully');
      print('   ✓ JSON serialization works');
      print('   ✓ Base64 serialization works');
      
      // Step 5: Test reconstruction capability
      print('5. Testing reconstruction capability...');
      final testShareSets = packages.take(3).map((p) => p.shareSet).toList();
      
      final reconstructedSecret = provider.reconstructedSecret;
      final reconstructionSuccess = await provider.reconstructSecret(
        testShareSets.map((s) => s.toBase64()).toList(),
      );
      
      expect(reconstructionSuccess, isTrue, reason: 'Reconstruction should succeed');
      expect(provider.reconstructedSecret, equals('This is a confidential message that needs to be shared securely'), 
        reason: 'Reconstructed secret should match original');
      
      print('   ✓ Secret reconstruction successful');
      print('   ✓ Reconstructed secret matches original');
      
      print('\n=== FLOW TEST COMPLETED SUCCESSFULLY ===\n');
    });
    
    test('Error handling during navigation race condition', () async {
      print('\n=== TESTING NAVIGATION RACE CONDITION HANDLING ===');
      
      // Step 1: Create secret successfully
      await provider.createSecret(
        secretName: 'Test Secret',
        secret: 'Test message',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(provider.isSecretReady, isTrue);
      
      // Step 2: Simulate race condition by clearing lastResult after creation
      print('1. Simulating race condition...');
      provider.clearResults();
      
      expect(provider.lastResult, isNull, reason: 'lastResult should be null after clearing');
      expect(provider.isSecretReady, isFalse, reason: 'Secret should not be ready after clearing');
      
      // Step 3: Try to get distribution packages (should return empty list)
      print('2. Testing package generation after clearing...');
      final packages = provider.getDistributionPackages();
      
      expect(packages, isEmpty, reason: 'Should return empty packages when lastResult is null');
      
      // Step 4: Verify error handling
      print('3. Verifying error handling...');
      expect(provider.errorMessage, isNull, reason: 'Should not set error message for cleared state');
      
      print('   ✓ Race condition handled gracefully');
      print('   ✓ Empty packages returned safely');
      print('   ✓ No unexpected errors thrown');
      
      print('\n=== RACE CONDITION TEST COMPLETED ===\n');
    });
    
    test('State validation prevents invalid navigation', () async {
      print('\n=== TESTING STATE VALIDATION ===');
      
      // Test 1: Empty secret name
      print('1. Testing empty secret name validation...');
      var success = await provider.createSecret(
        secretName: '',
        secret: 'Valid secret',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isFalse, reason: 'Should fail with empty name');
      expect(provider.isSecretReady, isFalse, reason: 'Should not be ready with failed creation');
      expect(provider.errorMessage, contains('Secret name cannot be empty'));
      
      provider.clearError();
      
      // Test 2: Empty secret content
      print('2. Testing empty secret content validation...');
      success = await provider.createSecret(
        secretName: 'Valid name',
        secret: '',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isFalse, reason: 'Should fail with empty secret');
      expect(provider.isSecretReady, isFalse, reason: 'Should not be ready with failed creation');
      expect(provider.errorMessage, contains('Secret cannot be empty'));
      
      provider.clearError();
      
      // Test 3: Whitespace-only inputs
      print('3. Testing whitespace-only inputs...');
      success = await provider.createSecret(
        secretName: '   ',
        secret: '   ',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(success, isFalse, reason: 'Should fail with whitespace-only inputs');
      expect(provider.isSecretReady, isFalse, reason: 'Should not be ready with failed creation');
      
      print('   ✓ All validation tests passed');
      print('   ✓ State remains consistent during validation failures');
      
      print('\n=== STATE VALIDATION TEST COMPLETED ===\n');
    });
    
    test('Multiple secret creations clear previous state', () async {
      print('\n=== TESTING STATE CLEARING BETWEEN OPERATIONS ===');
      
      // Create first secret
      print('1. Creating first secret...');
      await provider.createSecret(
        secretName: 'First Secret',
        secret: 'First secret message',
        threshold: 2,
        totalShares: 3,
      );
      
      expect(provider.isSecretReady, isTrue);
      final firstPackages = provider.getDistributionPackages();
      expect(firstPackages.length, equals(3));
      
      // Create second secret
      print('2. Creating second secret...');
      await provider.createSecret(
        secretName: 'Second Secret',
        secret: 'Second secret message',
        threshold: 3,
        totalShares: 5,
      );
      
      expect(provider.isSecretReady, isTrue);
      final secondPackages = provider.getDistributionPackages();
      expect(secondPackages.length, equals(5), reason: 'Should have 5 packages for second secret');
      expect(provider.lastResult!.threshold, equals(3), reason: 'Should have threshold from second secret');
      
      print('   ✓ Second secret replaced first secret');
      print('   ✓ Package count updated correctly');
      print('   ✓ Threshold updated correctly');
      
      print('\n=== STATE CLEARING TEST COMPLETED ===\n');
    });
  });
}