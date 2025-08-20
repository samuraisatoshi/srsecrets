import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

/// Trace the exact state flow to find where _lastResult gets cleared
void main() {
  test('Trace exact state flow during navigation', () {
    final provider = SecretProvider();
    
    print('\n=== TRACING STATE FLOW ===');
    
    // Step 1: Initial state
    print('1. Initial state:');
    print('   lastResult: ${provider.lastResult}');
    print('   isSecretReady: ${provider.isSecretReady}');
    
    // Step 2: CreateSecretScreen calls createSecret
    print('\n2. CreateSecretScreen calls createSecret():');
    final success = provider.createSecret(
      secretName: 'Test',
      secret: 'Secret',
      threshold: 2,
      totalShares: 3,
    );
    print('   success: $success');
    print('   lastResult: ${provider.lastResult}');
    print('   isSecretReady: ${provider.isSecretReady}');
    
    // Step 3: CreateSecretScreen validates isSecretReady
    print('\n3. CreateSecretScreen validates isSecretReady:');
    final isReady = provider.isSecretReady;
    print('   isSecretReady: $isReady');
    print('   lastResult still exists: ${provider.lastResult != null}');
    
    // Step 4: Navigation occurs (simulated)
    print('\n4. Navigation to ShareDistributionScreen...');
    
    // Step 5: ShareDistributionScreen builds
    print('\n5. ShareDistributionScreen builds:');
    print('   lastResult: ${provider.lastResult}');
    print('   Calling getDistributionPackages()...');
    
    final packages = provider.getDistributionPackages();
    print('   packages.length: ${packages.length}');
    
    // Check if something in the provider might be clearing state
    print('\n6. Checking provider state after getDistributionPackages:');
    print('   lastResult: ${provider.lastResult}');
    print('   isLoading: ${provider.isLoading}');
    print('   errorMessage: ${provider.errorMessage}');
    
    print('\n=== END TRACE ===\n');
  });
  
  test('Check if context.watch causes issues', () {
    final provider = SecretProvider();
    
    print('\n=== TESTING CONTEXT.WATCH SCENARIO ===');
    
    // Create secret
    provider.createSecret(
      secretName: 'Test',
      secret: 'Secret',
      threshold: 2,
      totalShares: 3,
    );
    
    print('After createSecret:');
    print('  lastResult: ${provider.lastResult != null}');
    
    // Simulate multiple watch calls (as would happen during navigation)
    for (int i = 0; i < 5; i++) {
      print('\nWatch call $i:');
      print('  isLoading: ${provider.isLoading}');
      print('  errorMessage: ${provider.errorMessage}');
      print('  lastResult: ${provider.lastResult != null}');
      print('  getDistributionPackages: ${provider.getDistributionPackages().length}');
    }
    
    print('\n=== END WATCH TEST ===\n');
  });
  
  test('Check if clearResults is being called unexpectedly', () {
    final provider = SecretProvider();
    
    print('\n=== TESTING CLEAR RESULTS ===');
    
    // Create secret
    provider.createSecret(
      secretName: 'Test',
      secret: 'Secret',
      threshold: 2,
      totalShares: 3,
    );
    
    print('After createSecret:');
    print('  lastResult: ${provider.lastResult != null}');
    
    // Test what clearResults does
    print('\nCalling clearResults():');
    provider.clearResults();
    print('  lastResult after clear: ${provider.lastResult}');
    print('  getDistributionPackages after clear: ${provider.getDistributionPackages().length}');
    
    print('\n=== END CLEAR TEST ===\n');
  });
}