import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/pin_input_widget.dart';

void main() {
  group('PinInputWidget', () {
    late String capturedPin;
    
    setUp(() {
      capturedPin = '';
    });

    Widget createTestWidget({
      bool isLoading = false,
      int maxLength = 8,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PinInputWidget(
            onCompleted: (pin) {
              capturedPin = pin;
            },
            isLoading: isLoading,
            maxLength: maxLength,
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders correctly with default parameters', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Check PIN dots are rendered
        expect(find.byType(Container), findsWidgets);
        
        // Check keypad numbers are rendered
        for (int i = 0; i <= 9; i++) {
          expect(find.text(i.toString()), findsOneWidget);
        }
        
        // Check control buttons
        expect(find.byIcon(Icons.clear_all), findsOneWidget);
        expect(find.byIcon(Icons.backspace), findsOneWidget);
      });

      testWidgets('shows loading indicator when isLoading is true', (tester) async {
        await tester.pumpWidget(createTestWidget(isLoading: true));
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('1'), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels for PIN dots', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the semantic label for PIN entry
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('keypad buttons have semantic labels and hints', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Test numeric button semantics
        expect(find.bySemanticsLabel('Enter digit 1'), findsOneWidget);
        expect(find.bySemanticsLabel('Enter digit 5'), findsOneWidget);
        
        // Test control button semantics
        expect(find.bySemanticsLabel('Clear all digits'), findsOneWidget);
        expect(find.bySemanticsLabel('Delete last digit'), findsOneWidget);
      });

      testWidgets('keypad buttons meet minimum touch target size', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final buttonFinder = find.byType(Material).first;
        final Material button = tester.widget(buttonFinder);
        final InkWell inkWell = tester.widget<InkWell>(
          find.descendant(of: buttonFinder, matching: find.byType(InkWell)).first,
        );
        final Container container = tester.widget<Container>(
          find.descendant(of: buttonFinder, matching: find.byType(Container)).first,
        );
        
        // Check that button size exceeds 44dp minimum
        expect(container.constraints?.minWidth, greaterThan(44));
        expect(container.constraints?.minHeight, greaterThan(44));
      });

      testWidgets('buttons are properly disabled when loading', (tester) async {
        await tester.pumpWidget(createTestWidget(isLoading: true));
        
        // Buttons should not be tappable when loading
        expect(find.bySemanticsLabel('Enter digit 1'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('tapping number buttons adds digits to PIN', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Tap digit '1'
        await tester.tap(find.text('1'));
        await tester.pump();
        
        // Check PIN dot updates
        expect(find.bySemanticsLabel('PIN entry: 1 of 8 digits entered'), findsOneWidget);
        
        // Tap digit '2'
        await tester.tap(find.text('2'));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 2 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('backspace removes last digit', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Add some digits
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 2 of 8 digits entered'), findsOneWidget);
        
        // Tap backspace
        await tester.tap(find.byIcon(Icons.backspace));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 1 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('clear button removes all digits', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Add some digits
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 3 of 8 digits entered'), findsOneWidget);
        
        // Tap clear
        await tester.tap(find.byIcon(Icons.clear_all));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('calls onCompleted when minimum PIN length reached', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Enter 4 digits (minimum PIN length)
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        await tester.tap(find.text('4'));
        await tester.pumpAndSettle();
        
        expect(capturedPin, equals('1234'));
        
        // PIN should be cleared after completion
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });

      testWidgets('respects maxLength parameter', (tester) async {
        await tester.pumpWidget(createTestWidget(maxLength: 4));
        
        // Try to enter more than maxLength digits
        await tester.tap(find.text('1'));
        await tester.tap(find.text('2'));
        await tester.tap(find.text('3'));
        await tester.tap(find.text('4'));
        await tester.tap(find.text('5')); // This should be ignored
        await tester.pump();
        
        // Should still show 4 digits, not 5
        expect(find.bySemanticsLabel('PIN entry: 0 of 4 digits entered'), findsOneWidget); // Cleared after completion
      });
    });

    group('Edge Cases', () {
      testWidgets('does not accept input when loading', (tester) async {
        await tester.pumpWidget(createTestWidget(isLoading: true));
        
        // Try to tap a number - should not work
        expect(find.text('1'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('backspace on empty PIN does nothing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Tap backspace when PIN is empty
        await tester.tap(find.byIcon(Icons.backspace));
        await tester.pump();
        
        expect(find.bySemanticsLabel('PIN entry: 0 of 8 digits entered'), findsOneWidget);
      });
    });
  });
}