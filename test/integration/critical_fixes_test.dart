import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:srsecrets/presentation/providers/secret_provider.dart';
import 'package:srsecrets/presentation/widgets/premium_pin_input.dart';
import 'package:srsecrets/presentation/widgets/pin_input_widget.dart';
import 'package:srsecrets/domains/crypto/shamir/shamir_secret_sharing.dart';

void main() {
  group('Critical Fixes Tests', () {
    group('PIN Input Security', () {
      testWidgets('Premium PIN input should not show device keyboard', (WidgetTester tester) async {
        bool pinCompleted = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumPinInput(
                onCompleted: (pin) => pinCompleted = true,
                minLength: 4,
                maxLength: 8,
              ),
            ),
          ),
        );
        
        // Find the hidden TextField
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        
        // Verify TextField has readOnly property set to true
        final TextField textField = tester.widget(textFieldFinder);
        expect(textField.readOnly, isTrue, reason: 'TextField must be readOnly to prevent keyboard');
        expect(textField.showCursor, isFalse, reason: 'Cursor should be hidden for security');
        expect(textField.enableInteractiveSelection, isFalse, reason: 'Text selection should be disabled');
      });
      
      testWidgets('Regular PIN input should not show device keyboard', (WidgetTester tester) async {
        bool pinCompleted = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PinInputWidget(
                onCompleted: (pin) => pinCompleted = true,
                minLength: 4,
                maxLength: 8,
              ),
            ),
          ),
        );
        
        // Find the hidden TextField
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        
        // Verify TextField has readOnly property set to true
        final TextField textField = tester.widget(textFieldFinder);
        expect(textField.readOnly, isTrue, reason: 'TextField must be readOnly to prevent keyboard');
        expect(textField.showCursor, isFalse, reason: 'Cursor should be hidden for security');
        expect(textField.enableInteractiveSelection, isFalse, reason: 'Text selection should be disabled');
      });
    });
    
    group('PIN Circle Layout', () {
      testWidgets('Premium PIN circles should be responsive and not overflow', (WidgetTester tester) async {
        // Test with different screen sizes
        for (final size in [
          const Size(320, 568), // Small phone
          const Size(375, 667), // iPhone 8
          const Size(414, 896), // iPhone 11
          const Size(768, 1024), // iPad
        ]) {
          await tester.binding.setSurfaceSize(size);
          
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PremiumPinInput(
                  onCompleted: (_) {},
                  minLength: 4,
                  maxLength: 8,
                ),
              ),
            ),
          );
          
          // Find the LayoutBuilder that contains PIN dots
          final layoutBuilderFinder = find.byType(LayoutBuilder);
          expect(layoutBuilderFinder, findsAtLeastNWidgets(1));
          
          // Ensure no overflow errors
          expect(tester.takeException(), isNull, reason: 'No overflow should occur at size $size');
        }
      });
    });
    
    group('Secret Generation Flow', () {
      test('SecretProvider should maintain lastResult after generation', () async {
        final provider = SecretProvider();
        
        // Create a secret
        final success = await provider.createSecret(
          secretName: 'Test Secret',
          secret: 'This is a test secret message',
          threshold: 2,
          totalShares: 3,
        );
        
        expect(success, isTrue, reason: 'Secret creation should succeed');
        expect(provider.lastResult, isNotNull, reason: 'lastResult should be set after creation');
        expect(provider.lastResult!.shareSets.length, equals(3), reason: 'Should have 3 share sets');
        
        // Get distribution packages
        final packages = provider.getDistributionPackages();
        expect(packages, isNotEmpty, reason: 'Distribution packages should not be empty');
        expect(packages.length, equals(3), reason: 'Should have 3 packages');
        
        // Verify each package
        for (int i = 0; i < packages.length; i++) {
          final package = packages[i];
          expect(package.participantNumber, equals(i + 1));
          expect(package.threshold, equals(2));
          expect(package.totalParticipants, equals(3));
          expect(package.shareSet, isNotNull);
        }
      });
      
      test('ShamirSecretSharing should create valid MultiSplitResult', () {
        const secret = 'Test secret for validation';
        const threshold = 2;
        const totalShares = 3;
        
        final result = ShamirSecretSharing.splitString(
          secret: secret,
          threshold: threshold,
          shares: totalShares,
        );
        
        expect(result, isNotNull);
        expect(result.shareSets, isNotEmpty);
        expect(result.shareSets.length, equals(totalShares));
        expect(result.threshold, equals(threshold));
        expect(result.totalShares, equals(totalShares));
        
        // Test createDistributionPackages
        final packages = result.createDistributionPackages();
        expect(packages, isNotEmpty);
        expect(packages.length, equals(totalShares));
        
        // Verify reconstruction works
        final reconstructed = ShamirSecretSharing.combineString(
          shareSets: result.shareSets.take(threshold).toList(),
        );
        expect(reconstructed, equals(secret));
      });
    });
  });
}