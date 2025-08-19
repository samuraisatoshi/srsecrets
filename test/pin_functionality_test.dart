import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:srsecrets/presentation/providers/auth_provider.dart';
import 'package:srsecrets/presentation/widgets/premium_pin_input.dart';
import 'package:srsecrets/presentation/widgets/pin_input_widget.dart';

void main() {
  group('PIN Functionality Tests', () {
    testWidgets('Premium PIN input accepts 4-8 digits', (WidgetTester tester) async {
      String? submittedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumPinInput(
              onCompleted: (pin) => submittedPin = pin,
              minLength: 4,
              maxLength: 8,
            ),
          ),
        ),
      );

      // Enter 3 digits - should not submit
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pump();
      
      // Submit button should be disabled
      expect(find.text('Enter 4+ digits'), findsOneWidget);
      expect(submittedPin, isNull);
      
      // Enter 4th digit - submit button should be enabled
      await tester.tap(find.text('4'));
      await tester.pump();
      
      // Submit button should now show 'Unlock'
      expect(find.text('Unlock'), findsOneWidget);
      
      // Scroll to make sure button is visible
      await tester.ensureVisible(find.text('Unlock'));
      await tester.pump();
      
      // Tap submit button
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      
      expect(submittedPin, equals('1234'));
    });

    testWidgets('PIN input shows length requirements', (WidgetTester tester) async {
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

      // Check that requirements are displayed
      expect(find.text('4-8 digits required • 0 entered'), findsOneWidget);
      
      // Enter some digits
      await tester.tap(find.text('5'));
      await tester.tap(find.text('6'));
      await tester.pump();
      
      // Check updated count
      expect(find.text('4-8 digits required • 2 entered'), findsOneWidget);
    });

    testWidgets('PIN setup mode keeps PIN after submission', (WidgetTester tester) async {
      String? submittedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumPinInput(
              onCompleted: (pin) => submittedPin = pin,
              minLength: 4,
              maxLength: 8,
              isSetupMode: true,
            ),
          ),
        ),
      );

      // Enter PIN
      await tester.tap(find.text('8'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('1'));
      await tester.pump();
      
      // Submit button should show 'Set PIN' in setup mode
      expect(find.text('Set PIN'), findsOneWidget);
      
      // Scroll to make sure button is visible
      await tester.ensureVisible(find.text('Set PIN'));
      await tester.pump();
      
      // Tap submit
      await tester.tap(find.text('Set PIN'));
      await tester.pump();
      
      expect(submittedPin, equals('8521'));
      
      // In setup mode, PIN should not be cleared
      // (would need to check internal state, but we can verify button text remains)
      expect(find.text('Set PIN'), findsOneWidget);
    });

    testWidgets('Clear button clears all digits', (WidgetTester tester) async {
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

      // Enter some digits
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.pump();
      
      expect(find.text('4-8 digits required • 3 entered'), findsOneWidget);
      
      // Tap clear
      await tester.tap(find.byIcon(Icons.clear_all_rounded));
      await tester.pump();
      
      // Should be back to 0
      expect(find.text('4-8 digits required • 0 entered'), findsOneWidget);
    });

    testWidgets('Backspace removes last digit', (WidgetTester tester) async {
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

      // Enter some digits
      await tester.tap(find.text('9'));
      await tester.tap(find.text('8'));
      await tester.tap(find.text('7'));
      await tester.pump();
      
      expect(find.text('4-8 digits required • 3 entered'), findsOneWidget);
      
      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      
      // Should have 2 digits
      expect(find.text('4-8 digits required • 2 entered'), findsOneWidget);
    });

    testWidgets('Cannot exceed maximum PIN length', (WidgetTester tester) async {
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

      // Enter 8 digits (max)
      for (int i = 1; i <= 8; i++) {
        await tester.tap(find.text(i.toString()));
        await tester.pump();
      }
      
      expect(find.text('4-8 digits required • 8 entered'), findsOneWidget);
      
      // Try to enter 9th digit
      await tester.tap(find.text('9'));
      await tester.pump();
      
      // Should still be 8
      expect(find.text('4-8 digits required • 8 entered'), findsOneWidget);
    });

    test('AuthProvider validates PIN correctly', () {
      final authProvider = AuthProvider();
      
      // Test invalid PINs
      expect(authProvider.isValidPin('123'), isFalse); // Too short
      expect(authProvider.isValidPin('123456789'), isFalse); // Too long
      expect(authProvider.isValidPin('abcd'), isFalse); // Not digits
      expect(authProvider.isValidPin('12a4'), isFalse); // Contains letter
      
      // Test valid PINs
      expect(authProvider.isValidPin('1234'), isTrue); // 4 digits
      expect(authProvider.isValidPin('12345'), isTrue); // 5 digits
      expect(authProvider.isValidPin('123456'), isTrue); // 6 digits
      expect(authProvider.isValidPin('1234567'), isTrue); // 7 digits
      expect(authProvider.isValidPin('12345678'), isTrue); // 8 digits
    });

    testWidgets('Regular PIN input widget works with flexible length', (WidgetTester tester) async {
      String? submittedPin;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinInputWidget(
              onCompleted: (pin) => submittedPin = pin,
              minLength: 4,
              maxLength: 8,
            ),
          ),
        ),
      );

      // Check requirements display
      expect(find.text('4-8 digits required • 0 entered'), findsOneWidget);
      
      // Enter 5 digits
      await tester.tap(find.text('5'));
      await tester.tap(find.text('4'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('1'));
      await tester.pump();
      
      // Should be able to submit with 5 digits
      expect(find.text('Continue'), findsOneWidget);
      
      // Scroll to make sure button is visible
      await tester.ensureVisible(find.text('Continue'));
      await tester.pump();
      
      await tester.tap(find.text('Continue'));
      await tester.pump();
      
      expect(submittedPin, equals('54321'));
    });
  });
}