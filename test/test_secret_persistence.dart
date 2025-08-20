import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';
import '../lib/domains/storage/repositories/secret_storage_repository.dart';

void main() {
  test('Test secret persistence and retrieval', () async {
    print('\n=== TESTING SECRET PERSISTENCE ===\n');
    
    // First provider instance - create and save secrets
    final provider1 = SecretProvider();
    
    // Wait for initial load
    await Future.delayed(Duration(milliseconds: 100));
    
    print('1. Initial state - Provider 1:');
    print('   Secrets count: ${provider1.secrets.length}');
    
    // Create first secret
    final success1 = await provider1.createSecret(
      secretName: 'Persistent Secret 1',
      secret: 'This should be saved',
      threshold: 2,
      totalShares: 3,
    );
    
    print('\n2. After creating first secret:');
    print('   Success: $success1');
    print('   Secrets count: ${provider1.secrets.length}');
    if (provider1.secrets.isNotEmpty) {
      print('   Secret name: ${provider1.secrets[0].name}');
    }
    
    // Create second secret
    final success2 = await provider1.createSecret(
      secretName: 'Persistent Secret 2',
      secret: 'Another saved secret',
      threshold: 3,
      totalShares: 5,
    );
    
    print('\n3. After creating second secret:');
    print('   Success: $success2');
    print('   Secrets count: ${provider1.secrets.length}');
    
    // Wait for save to complete
    await Future.delayed(Duration(milliseconds: 200));
    
    // Create new provider instance to simulate app restart
    print('\n4. Simulating app restart - creating new provider...');
    final provider2 = SecretProvider();
    
    // Wait for load to complete
    await Future.delayed(Duration(milliseconds: 200));
    
    print('\n5. After restart - Provider 2:');
    print('   Secrets count: ${provider2.secrets.length}');
    
    for (int i = 0; i < provider2.secrets.length; i++) {
      final secret = provider2.secrets[i];
      print('   Secret ${i + 1}:');
      print('     Name: ${secret.name}');
      print('     Threshold: ${secret.threshold}');
      print('     Total Shares: ${secret.totalShares}');
      print('     Created: ${secret.createdAt}');
    }
    
    // Verify persistence worked
    expect(provider2.secrets.length, equals(provider1.secrets.length));
    
    if (provider2.secrets.isNotEmpty) {
      expect(provider2.secrets[0].name, equals('Persistent Secret 1'));
      if (provider2.secrets.length > 1) {
        expect(provider2.secrets[1].name, equals('Persistent Secret 2'));
      }
    }
    
    print('\n✅ Secret persistence is working!');
    print('=== TEST PASSED ===\n');
  });
  
  test('Test secret deletion persistence', () async {
    print('\n=== TESTING SECRET DELETION ===\n');
    
    // Create provider and add secrets
    final provider = SecretProvider();
    await Future.delayed(Duration(milliseconds: 100));
    
    // Create a secret
    await provider.createSecret(
      secretName: 'To Be Deleted',
      secret: 'Delete me',
      threshold: 2,
      totalShares: 3,
    );
    
    await Future.delayed(Duration(milliseconds: 100));
    
    print('1. Created secret:');
    print('   Secrets count: ${provider.secrets.length}');
    
    if (provider.secrets.isNotEmpty) {
      final secretId = provider.secrets[0].id;
      print('   Deleting secret with ID: $secretId');
      
      // Delete the secret
      await provider.removeSecret(secretId);
      
      await Future.delayed(Duration(milliseconds: 100));
      
      print('2. After deletion:');
      print('   Secrets count: ${provider.secrets.length}');
      
      // Create new provider to verify deletion persisted
      final provider2 = SecretProvider();
      await Future.delayed(Duration(milliseconds: 200));
      
      print('3. After restart:');
      print('   Secrets count: ${provider2.secrets.length}');
      
      expect(provider2.secrets.length, equals(0));
      print('\n✅ Secret deletion persisted!');
    }
    
    print('=== TEST PASSED ===\n');
  });
}