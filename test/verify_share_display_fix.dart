import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

void main() {
  test('Verify share display formats are correct', () {
    final provider = SecretProvider();
    
    // Create secret
    final success = provider.createSecret(
      secretName: 'Test',
      secret: 'Secret Data',
      threshold: 2,
      totalShares: 3,
    );
    
    expect(success, isTrue);
    
    // Get packages
    final packages = provider.getDistributionPackages();
    expect(packages.length, equals(3));
    
    // Test each package format
    for (final package in packages) {
      // toBase64() should return a String
      final base64String = package.shareSet.toBase64();
      expect(base64String, isA<String>());
      expect(base64String.isNotEmpty, isTrue);
      print('Base64 format: ${base64String.substring(0, 20)}...');
      
      // toJson() should return a Map
      final jsonMap = package.shareSet.toJson();
      expect(jsonMap, isA<Map<String, dynamic>>());
      
      // jsonEncode should convert Map to String
      final jsonString = jsonEncode(jsonMap);
      expect(jsonString, isA<String>());
      expect(jsonString.isNotEmpty, isTrue);
      print('JSON string format: ${jsonString.substring(0, 50)}...');
    }
    
    print('\n✅ All share formats are correct!');
  });
}