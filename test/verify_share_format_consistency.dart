import 'package:flutter_test/flutter_test.dart';
import '../lib/presentation/providers/secret_provider.dart';

void main() {
  test('Verify all share copy formats use base64', () {
    final provider = SecretProvider();
    
    // Create secret
    final success = provider.createSecret(
      secretName: 'Format Test',
      secret: 'Test Secret Data',
      threshold: 3,
      totalShares: 5,
    );
    
    expect(success, isTrue);
    
    // Get packages
    final packages = provider.getDistributionPackages();
    expect(packages.length, equals(5));
    
    print('\n=== SHARE FORMAT CONSISTENCY TEST ===\n');
    
    // Test individual share format
    print('Individual Share Format (base64):');
    for (int i = 0; i < packages.length; i++) {
      final package = packages[i];
      final base64Share = package.shareSet.toBase64();
      
      // Base64 should be a string
      expect(base64Share, isA<String>());
      
      // Base64 should not contain raw JSON structure
      expect(base64Share.contains('"shares":['), isFalse);
      expect(base64Share.contains('"metadata":'), isFalse);
      
      // Show sample (first 50 chars)
      if (i == 0) {
        print('  Participant ${package.participantNumber}: ${base64Share.substring(0, 50)}...');
      }
    }
    
    print('\nCopy All Shares Format:');
    // Simulate what Copy All Shares does
    final allShares = packages.map((package) => {
      'participant': package.participantNumber,
      'share': package.shareSet.toBase64(),
    }).toList();
    
    // Check each share in the collection
    for (final shareData in allShares) {
      final share = shareData['share'] as String;
      
      // Should be base64, not JSON
      expect(share, isA<String>());
      expect(share.contains('"shares":['), isFalse);
      expect(share.contains('"metadata":'), isFalse);
    }
    
    // Show the final format
    final shareText = allShares.map((share) => 
      'Participant ${share['participant']}:\n${share['share']}'
    ).join('\n\n---\n\n');
    
    print('  Output format sample:');
    final lines = shareText.split('\n');
    for (int i = 0; i < 5 && i < lines.length; i++) {
      if (lines[i].length > 60) {
        print('  ${lines[i].substring(0, 60)}...');
      } else {
        print('  ${lines[i]}');
      }
    }
    
    print('\n✅ All share formats are consistent (base64)');
    print('✅ No raw JSON in copied shares');
    print('\n=== TEST PASSED ===\n');
  });
  
  test('Verify shares can be reconstructed from base64 format', () {
    final provider = SecretProvider();
    
    final originalSecret = 'This is my secret message';
    
    // Create secret
    provider.createSecret(
      secretName: 'Reconstruction Test',
      secret: originalSecret,
      threshold: 2,
      totalShares: 3,
    );
    
    // Get packages
    final packages = provider.getDistributionPackages();
    
    // Get base64 shares (as they would be copied)
    final base64Shares = packages
        .take(2) // Use threshold number of shares
        .map((p) => p.shareSet.toBase64())
        .toList();
    
    print('\nReconstruction Test:');
    print('  Original secret: "$originalSecret"');
    print('  Using ${base64Shares.length} shares in base64 format');
    
    // Reconstruct from base64 shares
    final reconstructSuccess = provider.reconstructSecret(base64Shares);
    expect(reconstructSuccess, isTrue);
    
    final reconstructed = provider.reconstructedSecret;
    expect(reconstructed, equals(originalSecret));
    
    print('  Reconstructed: "$reconstructed"');
    print('  ✅ Reconstruction successful from base64 shares!');
  });
}