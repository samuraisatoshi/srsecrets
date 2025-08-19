import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/error_display_widget.dart';

void main() {
  group('ErrorDisplayWidget', () {
    const testErrorMessage = 'Test error message';
    bool dismissCalled = false;

    setUp(() {
      dismissCalled = false;
    });

    Widget createTestWidget({
      String errorMessage = testErrorMessage,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorDisplayWidget(
            errorMessage: errorMessage,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders error message correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text(testErrorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('renders dismiss button when onDismiss provided', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onDismiss: () => dismissCalled = true,
        ));
        
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
      });

      testWidgets('does not render dismiss button when onDismiss is null', (tester) async {
        await tester.pumpWidget(createTestWidget(onDismiss: null));
        
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byType(IconButton), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels for error content', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Error: $testErrorMessage'), findsOneWidget);
        expect(find.bySemanticsLabel('Error icon'), findsOneWidget);
      });

      testWidgets('has proper semantic labels for dismiss button', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onDismiss: () => dismissCalled = true,
        ));
        
        expect(find.bySemanticsLabel('Dismiss error message'), findsOneWidget);
      });

      testWidgets('has live region semantics for screen reader announcements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the main Semantics widget with liveRegion
        final semanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.text(testErrorMessage),
            matching: find.byType(Semantics),
          ).first,
        );
        
        expect(semanticsWidget.properties.liveRegion, isTrue);
      });

      testWidgets('dismiss button has proper semantic properties', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onDismiss: () => dismissCalled = true,
        ));
        
        final dismissSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.byIcon(Icons.close),
            matching: find.byType(Semantics),
          ).first,
        );
        
        expect(dismissSemanticsWidget.properties.button, isTrue);
        expect(dismissSemanticsWidget.properties.label, contains('Dismiss error message'));
        expect(dismissSemanticsWidget.properties.hint, contains('Removes this error message'));
      });
    });

    group('User Interactions', () {
      testWidgets('calls onDismiss when dismiss button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onDismiss: () => dismissCalled = true,
        ));
        
        await tester.tap(find.byIcon(Icons.close));
        
        expect(dismissCalled, isTrue);
      });

      testWidgets('dismiss button has tooltip', (tester) async {
        await tester.pumpWidget(createTestWidget(
          onDismiss: () => dismissCalled = true,
        ));
        
        // Long press to show tooltip
        await tester.longPress(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        
        expect(find.text('Dismiss error'), findsOneWidget);
      });
    });

    group('Styling and Layout', () {
      testWidgets('uses error theme colors', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(testErrorMessage),
            matching: find.byType(Container),
          ).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      });

      testWidgets('has proper margins and padding', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(testErrorMessage),
            matching: find.byType(Container),
          ).first,
        );
        
        expect(container.margin, equals(const EdgeInsets.only(bottom: 16)));
        expect(container.padding, equals(const EdgeInsets.all(16)));
      });
    });

    group('Content Handling', () {
      testWidgets('handles long error messages', (tester) async {
        const longMessage = 'This is a very long error message that should wrap properly and not overflow the container boundaries. It should be displayed in multiple lines if needed.';
        
        await tester.pumpWidget(createTestWidget(errorMessage: longMessage));
        
        expect(find.text(longMessage), findsOneWidget);
        expect(find.bySemanticsLabel('Error: $longMessage'), findsOneWidget);
      });

      testWidgets('handles empty error messages gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(errorMessage: ''));
        
        expect(find.text(''), findsOneWidget);
        expect(find.bySemanticsLabel('Error: '), findsOneWidget);
      });

      testWidgets('handles special characters in error messages', (tester) async {
        const specialMessage = 'Error with symbols: !@#\$%^&*()_+-={}[]|\\:";\'<>?,./';
        
        await tester.pumpWidget(createTestWidget(errorMessage: specialMessage));
        
        expect(find.text(specialMessage), findsOneWidget);
        expect(find.bySemanticsLabel('Error: $specialMessage'), findsOneWidget);
      });
    });
  });
}