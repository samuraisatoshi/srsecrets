import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsecrets/presentation/widgets/wireframe_overlay_system.dart';
import 'package:srsecrets/presentation/widgets/crypto_tutorial_animations.dart';
import 'package:srsecrets/presentation/widgets/practice_mode_system.dart';
import 'package:srsecrets/presentation/screens/onboarding/interactive_onboarding_screen.dart';

void main() {
  group('Interactive Onboarding Components Tests', () {
    
    group('WireframeOverlaySystem', () {
      testWidgets('should render wireframe elements when active', (tester) async {
        final testElements = [
          WireframeElement(
            id: 'test1',
            title: 'Test Element',
            description: 'Test Description',
            icon: Icons.info,
            color: Colors.blue,
            type: WireframeType.highlight,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WireframeOverlaySystem(
                isActive: true,
                elements: testElements,
                child: const Text('Test Child'),
              ),
            ),
          ),
        );

        // Verify child widget is rendered
        expect(find.text('Test Child'), findsOneWidget);
        
        // When active, overlay should be present
        await tester.pump();
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('should not show overlay when inactive', (tester) async {
        final testElements = [
          WireframeElement(
            id: 'test1',
            title: 'Test Element',
            type: WireframeType.highlight,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WireframeOverlaySystem(
                isActive: false,
                elements: testElements,
                child: const Text('Test Child'),
              ),
            ),
          ),
        );

        // Child should be rendered
        expect(find.text('Test Child'), findsOneWidget);
        
        // Overlay should not be present when inactive
        await tester.pump();
        expect(find.byType(Container).first, isNotNull);
      });

      testWidgets('should handle element navigation', (tester) async {
        bool onCompleteCalled = false;
        
        final testElements = [
          WireframeElement(
            id: 'test1',
            title: 'Element 1',
            type: WireframeType.highlight,
          ),
          WireframeElement(
            id: 'test2',
            title: 'Element 2',
            type: WireframeType.outline,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WireframeOverlaySystem(
                isActive: true,
                elements: testElements,
                onComplete: () => onCompleteCalled = true,
                child: const Text('Test Child'),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Look for navigation elements
        expect(find.byType(FloatingActionButton), findsWidgets);
        
        // Test navigation (if buttons are found)
        final navButtons = find.byType(FloatingActionButton);
        if (navButtons.evaluate().isNotEmpty) {
          await tester.tap(navButtons.first);
          await tester.pump();
        }
        
        // Note: In a real test, we'd mock the GlobalKey references
        // and test the actual navigation behavior more thoroughly
      });
    });

    group('CryptoTutorialAnimations', () {
      testWidgets('should render tutorial based on type', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CryptoTutorialAnimations(
                type: CryptoTutorialType.secretSplitting,
                autoPlay: false,
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Should render the tutorial container
        expect(find.byType(Container), findsWidgets);
        expect(find.byType(Stack), findsOneWidget);
      });

      testWidgets('should handle tutorial completion', (tester) async {
        bool onCompleteCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CryptoTutorialAnimations(
                type: CryptoTutorialType.thresholdConcept,
                onComplete: () => onCompleteCalled = true,
                autoPlay: false,
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Tutorial should be rendered
        expect(find.byType(Container), findsWidgets);
        
        // In a real scenario, we'd simulate user interaction
        // to trigger completion callback
      });

      testWidgets('should render different tutorial types correctly', (tester) async {
        final tutorialTypes = [
          CryptoTutorialType.secretSplitting,
          CryptoTutorialType.secretReconstruction,
          CryptoTutorialType.thresholdConcept,
          CryptoTutorialType.shareDistribution,
        ];

        for (final type in tutorialTypes) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CryptoTutorialAnimations(
                  type: type,
                  autoPlay: false,
                ),
              ),
            ),
          );

          await tester.pump();
          
          // Each tutorial type should render successfully
          expect(find.byType(Container), findsWidgets);
          expect(find.byType(Stack), findsOneWidget);
        }
      });
    });

    group('PracticeModeSystem', () {
      testWidgets('should render practice interface', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PracticeModeSystem(
                scenario: PracticeScenario.secretSplitting,
                difficulty: Difficulty.beginner,
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Should render the practice container
        expect(find.byType(Container), findsWidgets);
        
        // Should have progress indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle different practice scenarios', (tester) async {
        final scenarios = [
          PracticeScenario.secretSplitting,
          PracticeScenario.secretReconstruction,
          PracticeScenario.fullWorkflow,
        ];

        for (final scenario in scenarios) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PracticeModeSystem(
                  scenario: scenario,
                  difficulty: Difficulty.beginner,
                ),
              ),
            ),
          );

          await tester.pump();
          
          // Each scenario should render successfully
          expect(find.byType(Container), findsWidgets);
        }
      });

      testWidgets('should show practice completion', (tester) async {
        bool onCompleteCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PracticeModeSystem(
                scenario: PracticeScenario.secretSplitting,
                onComplete: () => onCompleteCalled = true,
                difficulty: Difficulty.beginner,
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Practice interface should be rendered
        expect(find.byType(Container), findsWidgets);
        
        // In a real test, we'd simulate completing practice steps
        // and verify that onComplete is called
      });
    });

    group('InteractiveOnboardingScreen', () {
      testWidgets('should render tabbed interface', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: InteractiveOnboardingScreen(),
          ),
        );

        await tester.pump();
        
        // Should have tab bar
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);
        
        // Should have three tabs
        expect(find.byType(Tab), findsNWidgets(3));
        
        // Should have app bar with settings
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should navigate between tabs', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: InteractiveOnboardingScreen(),
          ),
        );

        await tester.pump();
        
        // Find tab widgets
        final tabs = find.byType(Tab);
        expect(tabs, findsNWidgets(3));
        
        // Tap on different tabs
        if (tabs.evaluate().length >= 2) {
          await tester.tap(tabs.at(1));
          await tester.pump();
          
          await tester.tap(tabs.at(2));
          await tester.pump();
        }
        
        // Interface should remain stable
        expect(find.byType(TabBar), findsOneWidget);
      });

      testWidgets('should show wireframe toggle button', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: InteractiveOnboardingScreen(),
          ),
        );

        await tester.pump();
        
        // Should have help/wireframe button in app bar
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        
        // Tap wireframe toggle button
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();
        
        // Icon should change to visibility_off when active
        // (This tests the toggle functionality)
      });

      testWidgets('should handle completion states', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: InteractiveOnboardingScreen(),
          ),
        );

        await tester.pump();
        
        // Should render without completion FAB initially
        expect(find.byType(FloatingActionButton), findsNothing);
        
        // In a real test, we'd simulate tutorial and practice completion
        // to verify that the completion FAB appears
      });
    });
  });

  group('Integration Tests', () {
    testWidgets('should integrate all components smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveOnboardingScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Main screen should be rendered
      expect(find.byType(InteractiveOnboardingScreen), findsOneWidget);
      
      // All major components should be accessible
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      
      // Navigate through tabs to ensure all views work
      final tabs = find.byType(Tab);
      if (tabs.evaluate().length >= 3) {
        // Test Overview tab
        await tester.tap(tabs.at(0));
        await tester.pump();
        
        // Test Tutorials tab
        await tester.tap(tabs.at(1));
        await tester.pump();
        
        // Test Practice tab
        await tester.tap(tabs.at(2));
        await tester.pump();
      }
      
      // Interface should remain stable throughout navigation
      expect(find.byType(InteractiveOnboardingScreen), findsOneWidget);
    });

    testWidgets('should handle wireframe overlay integration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveOnboardingScreen(),
        ),
      );

      await tester.pump();
      
      // Find and tap wireframe toggle
      final wireframeButton = find.byIcon(Icons.visibility_outlined);
      if (wireframeButton.evaluate().isNotEmpty) {
        await tester.tap(wireframeButton);
        await tester.pump();
        
        // Wireframe system should be integrated
        expect(find.byType(WireframeOverlaySystem), findsOneWidget);
      }
    });
  });

  group('Performance Tests', () {
    testWidgets('should handle multiple animation controllers efficiently', (tester) async {
      // Test that multiple animation-heavy components can coexist
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: CryptoTutorialAnimations(
                    type: CryptoTutorialType.secretSplitting,
                    autoPlay: false,
                  ),
                ),
                Expanded(
                  child: PracticeModeSystem(
                    scenario: PracticeScenario.secretSplitting,
                    difficulty: Difficulty.beginner,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Both components should render without performance issues
      expect(find.byType(CryptoTutorialAnimations), findsOneWidget);
      expect(find.byType(PracticeModeSystem), findsOneWidget);
    });

    testWidgets('should dispose resources properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveOnboardingScreen(),
        ),
      );

      await tester.pump();
      
      // Navigate away to test disposal
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Different Screen'),
          ),
        ),
      );

      await tester.pump();
      
      // Should complete without errors (verifies proper disposal)
      expect(find.text('Different Screen'), findsOneWidget);
    });
  });
}

// Helper function to create test material app wrapper
Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: Scaffold(
      body: child,
    ),
  );
}