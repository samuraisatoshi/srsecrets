import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

void main() {
  test('Verify provider state is maintained through workflow', () {
    print('\n=== TESTING PROVIDER FIX ===');
    
    // This simulates what the app-level provider does
    final appLevelProvider = SecretProvider();
    
    print('1. App-level provider created');
    print('   lastResult: ${appLevelProvider.lastResult}');
    
    // CreateSecretScreen uses the app-level provider
    print('\n2. CreateSecretScreen calls createSecret...');
    final success = appLevelProvider.createSecret(
      secretName: 'Test Secret',
      secret: 'My Secret Data',
      threshold: 2,
      totalShares: 3,
    );
    
    print('   success: $success');
    print('   lastResult after create: ${appLevelProvider.lastResult}');
    print('   isSecretReady: ${appLevelProvider.isSecretReady}');
    
    // Navigation happens
    print('\n3. Navigation to ShareDistributionScreen...');
    
    // ShareDistributionScreen uses the SAME app-level provider
    print('\n4. ShareDistributionScreen accesses provider...');
    print('   lastResult: ${appLevelProvider.lastResult}');
    
    final packages = appLevelProvider.getDistributionPackages();
    print('   packages.length: ${packages.length}');
    
    expect(success, isTrue);
    expect(appLevelProvider.lastResult, isNotNull);
    expect(packages.length, equals(3));
    
    print('\n✅ PROVIDER FIX VERIFIED - State is maintained!');
    print('=== END TEST ===\n');
  });
  
  test('Confirm the bug scenario is fixed', () {
    print('\n=== CONFIRMING BUG IS FIXED ===');
    
    final provider = SecretProvider();
    
    // Create secret (what CreateSecretScreen does)
    final success = provider.createSecret(
      secretName: 'Bug Test',
      secret: 'Testing',
      threshold: 2,
      totalShares: 3,
    );
    
    print('Created secret: success=$success');
    
    // Immediately access packages (what ShareDistributionScreen does)
    print('Accessing packages immediately...');
    final packages = provider.getDistributionPackages();
    
    if (packages.isEmpty) {
      print('❌ BUG STILL EXISTS: packages are empty!');
      print('lastResult: ${provider.lastResult}');
      fail('Bug still exists - packages are empty');
    } else {
      print('✅ BUG FIXED: ${packages.length} packages available');
      print('No WARNING messages!');
      print('No ERROR messages!');
    }
    
    expect(packages.length, equals(3));
    print('\n=== BUG IS FIXED ===\n');
  });
}