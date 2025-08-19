import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/widgets/secret_form_header.dart';

void main() {
  group('SecretFormHeader', () {
    const testTitle = 'Test Title';
    const testSubtitle = 'Test subtitle description';
    const testInfoText = 'Test information text';
    const testIcon = Icons.security;

    Widget createTestWidget({
      String title = testTitle,
      String subtitle = testSubtitle,
      IconData icon = testIcon,
      String? infoText,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SecretFormHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            infoText: infoText,
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('renders title, subtitle, and icon correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text(testTitle), findsOneWidget);
        expect(find.text(testSubtitle), findsOneWidget);
        expect(find.byIcon(testIcon), findsOneWidget);
      });

      testWidgets('renders info text when provided', (tester) async {
        await tester.pumpWidget(createTestWidget(infoText: testInfoText));
        
        expect(find.text(testInfoText), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('does not render info section when info text is null', (tester) async {
        await tester.pumpWidget(createTestWidget(infoText: null));
        
        expect(find.text(testInfoText), findsNothing);
        expect(find.byIcon(Icons.info_outline), findsNothing);
      });

      testWidgets('is wrapped in a Card', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels for main content', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.bySemanticsLabel('$testTitle. $testSubtitle'), findsOneWidget);
        expect(find.bySemanticsLabel('Section icon'), findsOneWidget);
      });

      testWidgets('title has header semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final titleSemanticsWidget = tester.widget<Semantics>(
          find.ancestor(
            of: find.text(testTitle),
            matching: find.byType(Semantics),
          ).where((widget) => {
            final semantics = widget as Semantics;
            return semantics.properties.header == true;
          }).first,
        );
        
        expect(titleSemanticsWidget.properties.header, isTrue);
      });

      testWidgets('has proper semantic labels for info section', (tester) async {
        await tester.pumpWidget(createTestWidget(infoText: testInfoText));
        
        expect(find.bySemanticsLabel('Information: $testInfoText'), findsOneWidget);
        expect(find.bySemanticsLabel('Information icon'), findsOneWidget);
      });

      testWidgets('excludes decorative elements from semantics', (tester) async {
        await tester.pumpWidget(createTestWidget(infoText: testInfoText));
        
        // Icon should be wrapped in ExcludeSemantics
        final iconSemanticsWidgets = tester.widgetList<ExcludeSemantics>(
          find.ancestor(
            of: find.byIcon(testIcon),
            matching: find.byType(ExcludeSemantics),
          ),
        );
        
        expect(iconSemanticsWidgets, isNotEmpty);
      });
    });

    group('Styling and Layout', () {
      testWidgets('has proper padding and margins', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final padding = tester.widget<Padding>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Padding),
          ).first,
        );
        
        expect(padding.padding, equals(const EdgeInsets.all(16.0)));
      });

      testWidgets('icon has proper size and spacing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final icon = tester.widget<Icon>(find.byIcon(testIcon));
        expect(icon.size, equals(28));
      });

      testWidgets('info container has proper styling when present', (tester) async {
        await tester.pumpWidget(createTestWidget(infoText: testInfoText));
        
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text(testInfoText),
            matching: find.byType(Container),
          ).first,
        );
        
        expect(container.padding, equals(const EdgeInsets.all(12)));
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
      });
    });

    group('Content Handling', () {
      testWidgets('handles long titles gracefully', (tester) async {
        const longTitle = 'This is a very long title that should wrap properly within the available space without causing layout issues or overflow problems';
        
        await tester.pumpWidget(createTestWidget(title: longTitle));
        
        expect(find.text(longTitle), findsOneWidget);
        expect(find.bySemanticsLabel('$longTitle. $testSubtitle'), findsOneWidget);
      });

      testWidgets('handles long subtitles gracefully', (tester) async {
        const longSubtitle = 'This is a very long subtitle that provides detailed information about the functionality and should wrap properly within the card container without causing any layout problems';
        
        await tester.pumpWidget(createTestWidget(subtitle: longSubtitle));
        
        expect(find.text(longSubtitle), findsOneWidget);
        expect(find.bySemanticsLabel('$testTitle. $longSubtitle'), findsOneWidget);
      });

      testWidgets('handles long info text gracefully', (tester) async {
        const longInfoText = 'This is very detailed information text that explains complex concepts and requirements. It should be properly displayed within the info container with appropriate wrapping and formatting to ensure good readability and user experience.';
        
        await tester.pumpWidget(createTestWidget(infoText: longInfoText));
        
        expect(find.text(longInfoText), findsOneWidget);
        expect(find.bySemanticsLabel('Information: $longInfoText'), findsOneWidget);
      });

      testWidgets('handles empty strings gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(
          title: '',
          subtitle: '',
          infoText: '',
        ));
        
        expect(find.text(''), findsWidgets);
        expect(find.bySemanticsLabel('. '), findsOneWidget);
      });
    });

    group('Theme Integration', () {
      testWidgets('uses theme colors properly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final BuildContext context = tester.element(find.byType(SecretFormHeader));
        final theme = Theme.of(context);
        
        final icon = tester.widget<Icon>(find.byIcon(testIcon));
        expect(icon.color, equals(theme.colorScheme.primary));
      });

      testWidgets('uses theme text styles', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final titleText = tester.widget<Text>(find.text(testTitle));
        expect(titleText.style?.fontWeight, equals(FontWeight.bold));
      });
    });

    group('Different Icon Types', () {
      testWidgets('works with different icon types', (tester) async {
        const icons = [
          Icons.add_circle_outline,
          Icons.restore,
          Icons.settings,
          Icons.lock,
          Icons.key,
        ];
        
        for (final icon in icons) {
          await tester.pumpWidget(createTestWidget(icon: icon));
          expect(find.byIcon(icon), findsOneWidget);
        }
      });
    });
  });
}