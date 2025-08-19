import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/share_input_widget.dart';

void main() {
  group('ShareInputWidget', () {
    late TextEditingController controller;
    late FocusNode focusNode;
    bool removeCalled = false;
    bool pasteCalled = false;

    setUp(() {
      controller = TextEditingController();
      focusNode = FocusNode();
      removeCalled = false;
      pasteCalled = false;
    });

    tearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    Widget createTestWidget({
      int index = 0,
      bool canRemove = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            child: ShareInputWidget(
              controller: controller,
              focusNode: focusNode,
              index: index,
              canRemove: canRemove,
              onRemove: () => removeCalled = true,
              onPaste: () => pasteCalled = true,
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders text field with correct label', (tester) async {
        await tester.pumpWidget(createTestWidget(index: 2));
        
        expect(find.text('Share 3'), findsOneWidget); // index + 1
        expect(find.text('Paste or enter share data'), findsOneWidget);
      });

      testWidgets('renders paste button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byIcon(Icons.paste), findsOneWidget);
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('renders remove button when canRemove is true', (tester) async {
        await tester.pumpWidget(createTestWidget(canRemove: true));
        
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      });

      testWidgets('does not render remove button when canRemove is false', (tester) async {
        await tester.pumpWidget(createTestWidget(canRemove: false));
        
        expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels for share input', (tester) async {
        await tester.pumpWidget(createTestWidget(index: 1));
        
        expect(find.bySemanticsLabel('Share input 2'), findsOneWidget);
        expect(find.bySemanticsLabel('Share 2 input field'), findsOneWidget);
      });

      testWidgets('has semantic hints for input field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final inputSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.byType(TextFormField),
            matching: find.byType(Semantics),
          ).where((widget) => {
            final semantics = widget as Semantics;
            return semantics.properties.hint?.contains('Enter or paste') == true;
          }).first,
        );
        
        expect(inputSemanticsWidget.properties.textField, isTrue);
        expect(inputSemanticsWidget.properties.hint, contains('Enter or paste the share data'));
      });

      testWidgets('paste button has proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Paste from clipboard'), findsOneWidget);
        
        final pasteSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.byIcon(Icons.paste),
            matching: find.byType(Semantics),
          ).where((widget) => {
            final semantics = widget as Semantics;
            return semantics.properties.button == true;
          }).first,
        );
        
        expect(pasteSemanticsWidget.properties.button, isTrue);
        expect(pasteSemanticsWidget.properties.hint, contains('Paste share data from device clipboard'));
      });

      testWidgets('remove button has proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget(index: 1, canRemove: true));
        
        expect(find.bySemanticsLabel('Remove share 2'), findsOneWidget);
        
        final removeSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.byIcon(Icons.remove_circle_outline),
            matching: find.byType(Semantics),
          ).first,
        );
        
        expect(removeSemanticsWidget.properties.button, isTrue);
        expect(removeSemanticsWidget.properties.hint, contains('Removes this share input field'));
      });

      testWidgets('remove button meets minimum touch target size', (tester) async {
        await tester.pumpWidget(createTestWidget(canRemove: true));
        
        final containerWidget = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.remove_circle_outline),
            matching: find.byType(Container),
          ).first,
        );
        
        final constraints = containerWidget.constraints!;
        expect(constraints.minWidth, equals(48));
        expect(constraints.minHeight, equals(48));
      });

      testWidgets('decorative icons are excluded from semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Key icon should be wrapped in ExcludeSemantics
        final keyIconSemanticsWidgets = tester.widgetList<ExcludeSemantics>(
          find.ancestor(
            of: find.byIcon(Icons.key),
            matching: find.byType(ExcludeSemantics),
          ),
        );
        
        expect(keyIconSemanticsWidgets, isNotEmpty);
      });
    });

    group('User Interactions', () {
      testWidgets('calls onPaste when paste button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.byIcon(Icons.paste));
        
        expect(pasteCalled, isTrue);
      });

      testWidgets('calls onRemove when remove button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(canRemove: true));
        
        await tester.tap(find.byIcon(Icons.remove_circle_outline));
        
        expect(removeCalled, isTrue);
      });

      testWidgets('paste button shows tooltip on long press', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        await tester.longPress(find.byIcon(Icons.paste));
        await tester.pumpAndSettle();
        
        expect(find.text('Paste from clipboard'), findsOneWidget);
      });

      testWidgets('remove button shows tooltip on long press', (tester) async {
        await tester.pumpWidget(createTestWidget(index: 2, canRemove: true));
        
        await tester.longPress(find.byIcon(Icons.remove_circle_outline));
        await tester.pumpAndSettle();
        
        expect(find.text('Remove share 3'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('shows error when field is empty', (tester) async {
        await tester.pumpWidget(createTestWidget(index: 0));
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Share 1 is required'), findsOneWidget);
      });

      testWidgets('shows error for invalid share format', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        controller.text = 'invalid_share_format';
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Invalid share format'), findsOneWidget);
      });

      testWidgets('accepts valid JSON share format', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        controller.text = '{"share":"valid_json_share","index":1}';
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
        expect(find.text('Share 1 is required'), findsNothing);
        expect(find.text('Invalid share format'), findsNothing);
      });

      testWidgets('accepts valid base64 share format', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        controller.text = 'dGVzdF92YWxpZF9iYXNlNjRfc2hhcmU=';
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
        expect(find.text('Share 1 is required'), findsNothing);
        expect(find.text('Invalid share format'), findsNothing);
      });
    });

    group('Text Input Behavior', () {
      testWidgets('supports multiline input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.maxLines, equals(3));
        expect(textField.minLines, equals(1));
      });

      testWidgets('focuses correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.byType(TextFormField));
        await tester.pumpAndSettle();
        
        expect(focusNode.hasFocus, isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles whitespace-only input as empty', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        controller.text = '   \t\n  ';
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Share 1 is required'), findsOneWidget);
      });

      testWidgets('handles very long share inputs', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Create a very long but valid base64 string
        final longBase64 = 'A' * 1000 + '==';
        controller.text = longBase64;
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
      });
    });

    group('Index Display', () {
      testWidgets('displays correct index in labels (1-based)', (tester) async {
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(createTestWidget(index: i));
          
          expect(find.text('Share ${i + 1}'), findsOneWidget);
          expect(find.bySemanticsLabel('Share input ${i + 1}'), findsOneWidget);
        }
      });
    });
  });
}