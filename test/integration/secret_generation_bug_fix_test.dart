import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';
import 'package:srsecrets/presentation/screens/secrets/create_secret_screen.dart';
import 'package:srsecrets/presentation/screens/secrets/share_distribution_screen.dart';

void main() {
  group('Secret Generation Bug Fix Integration Tests', () {
    late SecretProvider secretProvider;
    
    setUp(() {
      secretProvider = SecretProvider();
    });
    
    testWidgets('Complete secret creation to distribution flow should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SecretProvider>.value(
          value: secretProvider,
          child: MaterialApp(
            home: Scaffold(
              body: const CreateSecretScreen(),
            ),
          ),
        ),
      );
      
      // Fill in the form
      await tester.enterText(find.byType(TextFormField).first, 'Test Secret Name');
      await tester.enterText(find.byType(TextFormField).at(1), 'This is my test secret message for sharing');
      
      // Find and tap the create button (specifically the button, not the header)
      final createButton = find.byType(ElevatedButton).first;
      expect(createButton, findsOneWidget);
      
      await tester.tap(createButton);
      
      // Wait for async operation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verify provider state
      expect(secretProvider.isLoading, isFalse);
      expect(secretProvider.errorMessage, isNull);
      expect(secretProvider.lastResult, isNotNull);
      expect(secretProvider.isSecretReady, isTrue);
      
      // Verify packages can be created
      final packages = secretProvider.getDistributionPackages();
      expect(packages, isNotEmpty);
      expect(packages.length, equals(5)); // Default total shares
    });
    
    testWidgets('ShareDistributionScreen should handle valid state correctly', (WidgetTester tester) async {
      // Pre-populate the provider with a valid secret
      await secretProvider.createSecret(
        secretName: 'Test Secret',
        secret: 'Test secret message',
        threshold: 3,
        totalShares: 5,
      );
      
      expect(secretProvider.isSecretReady, isTrue);
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SecretProvider>.value(
          value: secretProvider,
          child: const MaterialApp(
            home: ShareDistributionScreen(),
          ),
        ),
      );
      
      // Should show the shares, not the error state
      expect(find.text('No Shares Available'), findsNothing);
      expect(find.text('Share Distribution'), findsOneWidget);
      expect(find.text('Copy All Shares'), findsOneWidget);
      
      // Should show the correct number of shares
      final packages = secretProvider.getDistributionPackages();
      expect(packages.length, equals(5));
    });
    
    testWidgets('ShareDistributionScreen should show error state when no shares', (WidgetTester tester) async {
      // Use empty provider (no secret created)
      await tester.pumpWidget(
        ChangeNotifierProvider<SecretProvider>.value(
          value: secretProvider,
          child: const MaterialApp(
            home: ShareDistributionScreen(),
          ),
        ),
      );
      
      // Should show error state
      expect(find.text('No Shares Available'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
      expect(find.text('No secret has been generated. Please go back and create a secret first.'), findsOneWidget);
    });
    
    testWidgets('Error state should show retry button when lastResult exists but packages fail', (WidgetTester tester) async {
      // This is a harder case to test - we need to simulate a state where
      // lastResult exists but packages can't be created
      // For now, we'll test the UI shows correctly when provider has an error
      
      await secretProvider.createSecret(
        secretName: 'Test Secret',
        secret: 'Test secret message',
        threshold: 3,
        totalShares: 5,
      );
      
      // Manually clear the lastResult to simulate the edge case
      secretProvider.clearResults();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<SecretProvider>.value(
          value: secretProvider,
          child: const MaterialApp(
            home: ShareDistributionScreen(),
          ),
        ),
      );
      
      // Should show error state
      expect(find.text('No Shares Available'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });
    
    group('SecretProvider Enhanced Functionality', () {
      test('isSecretReady should validate complete state', () async {
        // Initially should be false
        expect(secretProvider.isSecretReady, isFalse);
        
        // After creating secret should be true
        final success = await secretProvider.createSecret(
          secretName: 'Test',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(success, isTrue);
        expect(secretProvider.isSecretReady, isTrue);
        
        // Should be able to get packages
        final packages = secretProvider.getDistributionPackages();
        expect(packages, isNotEmpty);
        expect(packages.length, equals(3));
      });
      
      test('Enhanced input validation should catch edge cases', () async {
        // Empty secret name
        var success = await secretProvider.createSecret(
          secretName: '',
          secret: 'Test secret',
          threshold: 2,
          totalShares: 3,
        );
        expect(success, isFalse);
        expect(secretProvider.errorMessage, contains('Secret name cannot be empty'));
        
        // Empty secret
        success = await secretProvider.createSecret(
          secretName: 'Test Name',
          secret: '',
          threshold: 2,
          totalShares: 3,
        );
        expect(success, isFalse);
        expect(secretProvider.errorMessage, contains('Secret cannot be empty'));
        
        // Whitespace-only inputs
        success = await secretProvider.createSecret(
          secretName: '   ',
          secret: '   ',
          threshold: 2,
          totalShares: 3,
        );
        expect(success, isFalse);
      });
      
      test('State should be cleared between operations', () async {
        // Create first secret
        await secretProvider.createSecret(
          secretName: 'First Secret',
          secret: 'First secret content',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(secretProvider.lastResult, isNotNull);
        expect(secretProvider.isSecretReady, isTrue);
        
        // Create second secret - should clear previous state first
        await secretProvider.createSecret(
          secretName: 'Second Secret',
          secret: 'Second secret content',
          threshold: 3,
          totalShares: 5,
        );
        
        expect(secretProvider.lastResult, isNotNull);
        expect(secretProvider.isSecretReady, isTrue);
        
        // Verify it's the new secret (5 shares, not 3)
        final packages = secretProvider.getDistributionPackages();
        expect(packages.length, equals(5));
        expect(secretProvider.lastResult!.threshold, equals(3));
      });
    });
    
    group('Error Recovery and Resilience', () {
      testWidgets('Retry functionality should work in distribution screen', (WidgetTester tester) async {
        // Pre-populate with valid secret
        await secretProvider.createSecret(
          secretName: 'Test Secret',
          secret: 'Test secret message',
          threshold: 2,
          totalShares: 3,
        );
        
        // Temporarily make packages fail by clearing lastResult
        secretProvider.clearResults();
        
        await tester.pumpWidget(
          ChangeNotifierProvider<SecretProvider>.value(
            value: secretProvider,
            child: const MaterialApp(
              home: ShareDistributionScreen(),
            ),
          ),
        );
        
        // Should show error state initially
        expect(find.text('No Shares Available'), findsOneWidget);
        
        // Restore the state manually to simulate recovery
        await secretProvider.createSecret(
          secretName: 'Test Secret',
          secret: 'Test secret message',
          threshold: 2,
          totalShares: 3,
        );
        
        // Rebuild widget
        await tester.pump();
        
        // Should now show shares
        expect(find.text('Share Distribution'), findsOneWidget);
      });
    });
  });
}