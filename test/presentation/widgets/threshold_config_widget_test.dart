import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/threshold_config_widget.dart';

void main() {
  group('ThresholdConfigWidget', () {
    late TextEditingController thresholdController;
    late TextEditingController totalSharesController;

    setUp(() {
      thresholdController = TextEditingController(text: '3');
      totalSharesController = TextEditingController(text: '5');
    });

    tearDown() {
      thresholdController.dispose();
      totalSharesController.dispose();
    }

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Form(
            child: ThresholdConfigWidget(
              thresholdController: thresholdController,
              totalSharesController: totalSharesController,
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders all required elements', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Sharing Configuration'), findsOneWidget);
        expect(find.text('Threshold (k)'), findsOneWidget);
        expect(find.text('Total Shares (n)'), findsOneWidget);
        expect(find.byIcon(Icons.key), findsOneWidget);
        expect(find.byIcon(Icons.group), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('renders helper texts', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Min shares needed'), findsOneWidget);
        expect(find.text('Total shares created'), findsOneWidget);
      });

      testWidgets('renders dynamic explanation text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Any 3 of 5 shares can reconstruct the secret'), findsOneWidget);
      });

      testWidgets('updates explanation text when controllers change', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        thresholdController.text = '2';
        totalSharesController.text = '7';
        await tester.pump();
        
        expect(find.text('Any 2 of 7 shares can reconstruct the secret'), findsOneWidget);
      });

      testWidgets('shows placeholder when fields are empty', (tester) async {
        thresholdController.clear();
        totalSharesController.clear();
        
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Any k of n shares can reconstruct the secret'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels for main section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Sharing configuration section'), findsOneWidget);
      });

      testWidgets('header has proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final headerSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.text('Sharing Configuration'),
            matching: find.byType(Semantics),
          ).where((widget) => {
            final semantics = widget as Semantics;
            return semantics.properties.header == true;
          }).first,
        );
        
        expect(headerSemanticsWidget.properties.header, isTrue);
      });

      testWidgets('input fields have proper semantic labels and hints', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Threshold value input'), findsOneWidget);
        expect(find.bySemanticsLabel('Total shares input'), findsOneWidget);
        
        final thresholdSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.text('Threshold (k)').first,
            matching: find.byType(Semantics),
          ).where((widget) => {
            final semantics = widget as Semantics;
            return semantics.properties.textField == true;
          }).first,
        );
        
        expect(thresholdSemanticsWidget.properties.textField, isTrue);
        expect(thresholdSemanticsWidget.properties.hint, contains('minimum number of shares'));
      });

      testWidgets('explanation has proper semantic label', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('Configuration explanation: Any 3 of 5 shares can reconstruct the secret'), findsOneWidget);
      });

      testWidgets('decorative icons are excluded from semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Key and group icons should be wrapped in ExcludeSemantics
        final keyIconSemanticsWidgets = tester.widgetList<ExcludeSemantics>(
          find.ancestor(
            of: find.byIcon(Icons.key),
            matching: find.byType(ExcludeSemantics),
          ),
        );
        
        final groupIconSemanticsWidgets = tester.widgetList<ExcludeSemantics>(
          find.ancestor(
            of: find.byIcon(Icons.group),
            matching: find.byType(ExcludeSemantics),
          ),
        );
        
        expect(keyIconSemanticsWidgets, isNotEmpty);
        expect(groupIconSemanticsWidgets, isNotEmpty);
      });
    });

    group('Form Validation', () {
      testWidgets('validates threshold field as required', (tester) async {
        thresholdController.clear();
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Required'), findsAtLeastNWidgets(1));
      });

      testWidgets('validates total shares field as required', (tester) async {
        totalSharesController.clear();
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Required'), findsAtLeastNWidgets(1));
      });

      testWidgets('validates threshold minimum value', (tester) async {
        thresholdController.text = '1';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≥ 2'), findsOneWidget);
      });

      testWidgets('validates total shares minimum value', (tester) async {
        totalSharesController.text = '1';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≥ 2'), findsAtLeastNWidgets(1));
      });

      testWidgets('validates total shares maximum value', (tester) async {
        totalSharesController.text = '256';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≤ 255'), findsOneWidget);
      });

      testWidgets('validates threshold not greater than total shares', (tester) async {
        thresholdController.text = '6';
        totalSharesController.text = '5';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≤ total shares'), findsOneWidget);
      });

      testWidgets('validates total shares not less than threshold', (tester) async {
        thresholdController.text = '5';
        totalSharesController.text = '3';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≥ threshold'), findsOneWidget);
      });

      testWidgets('passes validation with valid values', (tester) async {
        thresholdController.text = '3';
        totalSharesController.text = '5';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
        expect(find.text('Required'), findsNothing);
        expect(find.text('Must be ≥ 2'), findsNothing);
      });
    });

    group('Input Behavior', () {
      testWidgets('accepts only numeric input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final thresholdField = find.byKey(const ValueKey('threshold')).first;
        await tester.tap(find.byType(TextFormField).first);
        await tester.enterText(find.byType(TextFormField).first, 'abc123def');
        
        expect(thresholdController.text, equals('123'));
      });

      testWidgets('has numeric keyboard type', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final thresholdField = tester.widget<TextFormField>(
          find.byType(TextFormField).first,
        );
        final totalSharesField = tester.widget<TextFormField>(
          find.byType(TextFormField).last,
        );
        
        expect(thresholdField.keyboardType, equals(TextInputType.number));
        expect(totalSharesField.keyboardType, equals(TextInputType.number));
      });
    });

    group('Layout and Styling', () {
      testWidgets('is wrapped in a Card', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('has proper padding', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final padding = tester.widget<Padding>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Padding),
          ).first,
        );
        
        expect(padding.padding, equals(const EdgeInsets.all(16.0)));
      });

      testWidgets('input fields are arranged in a row', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final row = tester.widget<Row>(
          find.ancestor(
            of: find.byType(TextFormField).first,
            matching: find.byType(Row),
          ).first,
        );
        
        expect(row.children.length, greaterThanOrEqualTo(2));
      });

      testWidgets('info container has proper styling', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.info_outline),
            matching: find.byType(Container),
          ).first,
        );
        
        expect(container.padding, equals(const EdgeInsets.all(12)));
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles empty string input gracefully', (tester) async {
        thresholdController.text = '';
        totalSharesController.text = '';
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Any k of n shares can reconstruct the secret'), findsOneWidget);
      });

      testWidgets('handles single character input', (tester) async {
        thresholdController.text = '2';
        totalSharesController.text = '3';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
      });

      testWidgets('handles maximum valid values', (tester) async {
        thresholdController.text = '255';
        totalSharesController.text = '255';
        await tester.pumpWidget(createTestWidget());
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        
        expect(isValid, isTrue);
        expect(find.text('Any 255 of 255 shares can reconstruct the secret'), findsOneWidget);
      });
    });

    group('Cross-field Validation', () {
      testWidgets('updates validation when threshold changes', (tester) async {
        thresholdController.text = '3';
        totalSharesController.text = '5';
        await tester.pumpWidget(createTestWidget());
        
        // Change threshold to exceed total shares
        await tester.enterText(find.byType(TextFormField).first, '6');
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≤ total shares'), findsOneWidget);
      });

      testWidgets('updates validation when total shares changes', (tester) async {
        thresholdController.text = '5';
        totalSharesController.text = '5';
        await tester.pumpWidget(createTestWidget());
        
        // Change total shares to be less than threshold
        await tester.enterText(find.byType(TextFormField).last, '3');
        
        final formState = tester.state<FormState>(find.byType(Form));
        final isValid = formState.validate();
        await tester.pumpAndSettle();
        
        expect(isValid, isFalse);
        expect(find.text('Must be ≥ threshold'), findsOneWidget);
      });
    });
  });
}