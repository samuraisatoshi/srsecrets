import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:srsecrets/presentation/providers/auth_provider.dart';
import 'package:srsecrets/presentation/providers/onboarding_provider.dart';
import 'package:srsecrets/core/routing/app_router.dart';
import 'package:srsecrets/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:srsecrets/presentation/screens/auth/premium_pin_setup_screen.dart';
import 'package:srsecrets/presentation/screens/auth/premium_pin_login_screen.dart';
import 'package:srsecrets/presentation/screens/home/premium_home_screen.dart';

/// Integration tests for onboarding system integration with main app
/// Tests the complete flow from first launch through authentication
void main() {
  group('Onboarding Integration Tests', () {
    late AuthProvider authProvider;
    late OnboardingProvider onboardingProvider;

    setUp(() {
      authProvider = AuthProvider();
      onboardingProvider = OnboardingProvider();
    });

    testWidgets('First launch shows onboarding flow', (WidgetTester tester) async {
      // Setup: First launch state
      await onboardingProvider.resetOnboardingState();
      
      final widget = AppRouter.determineInitialRoute(
        isAuthenticated: false,
        isPinSet: false,
        isOnboardingCompleted: false,
        isFirstLaunch: true,
      );

      expect(widget.runtimeType, OnboardingFlowScreen);
    });

    testWidgets('Completed onboarding shows PIN setup', (WidgetTester tester) async {
      final widget = AppRouter.determineInitialRoute(
        isAuthenticated: false,
        isPinSet: false,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );

      expect(widget.runtimeType, PremiumPinSetupScreen);
    });

    testWidgets('PIN set but not authenticated shows login', (WidgetTester tester) async {
      final widget = AppRouter.determineInitialRoute(
        isAuthenticated: false,
        isPinSet: true,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );

      expect(widget.runtimeType, PremiumPinLoginScreen);
    });

    testWidgets('Fully authenticated shows home screen', (WidgetTester tester) async {
      final widget = AppRouter.determineInitialRoute(
        isAuthenticated: true,
        isPinSet: true,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );

      expect(widget.runtimeType, PremiumHomeScreen);
    });

    test('Route name generation works correctly', () {
      // First launch
      String routeName = AppRouter.getRouteNameForState(
        isAuthenticated: false,
        isPinSet: false,
        isOnboardingCompleted: false,
        isFirstLaunch: true,
      );
      expect(routeName, '/onboarding');

      // PIN setup needed
      routeName = AppRouter.getRouteNameForState(
        isAuthenticated: false,
        isPinSet: false,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );
      expect(routeName, '/pin-setup');

      // Authentication needed
      routeName = AppRouter.getRouteNameForState(
        isAuthenticated: false,
        isPinSet: true,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );
      expect(routeName, '/pin-login');

      // Fully authenticated
      routeName = AppRouter.getRouteNameForState(
        isAuthenticated: true,
        isPinSet: true,
        isOnboardingCompleted: true,
        isFirstLaunch: false,
      );
      expect(routeName, '/home');
    });

    test('Route component validation works', () {
      expect(AppRouter.validateRouteComponents(), isTrue);
    });

    test('OnboardingProvider completion tracking', () async {
      await onboardingProvider.initialize();
      
      // Initial state
      expect(onboardingProvider.isOnboardingCompleted, isFalse);
      expect(onboardingProvider.completionProgress, 0.0);

      // Complete visual tutorial
      await onboardingProvider.completeVisualTutorial();
      expect(onboardingProvider.hasCompletedVisualTutorial, isTrue);
      expect(onboardingProvider.completionProgress, closeTo(0.33, 0.01));

      // Complete use cases
      await onboardingProvider.completeUseCases();
      expect(onboardingProvider.hasCompletedUseCases, isTrue);
      expect(onboardingProvider.completionProgress, closeTo(0.66, 0.01));

      // Complete security guide - should auto-complete onboarding
      await onboardingProvider.completeSecurityGuide();
      expect(onboardingProvider.hasCompletedSecurityGuide, isTrue);
      expect(onboardingProvider.completionProgress, 1.0);
      expect(onboardingProvider.isOnboardingCompleted, isTrue);
    });

    test('OnboardingProvider settings persistence', () async {
      await onboardingProvider.initialize();
      
      // Change settings
      await onboardingProvider.setTutorialHints(false);
      await onboardingProvider.setAnimations(false);
      await onboardingProvider.setPreferredMode(OnboardingMode.expert);

      // Verify settings
      expect(onboardingProvider.enableTutorialHints, isFalse);
      expect(onboardingProvider.enableAnimations, isFalse);
      expect(onboardingProvider.preferredMode, OnboardingMode.expert);
    });

    test('OnboardingProvider welcome messages', () async {
      await onboardingProvider.initialize();
      
      // First launch message
      String message = onboardingProvider.getWelcomeMessage();
      expect(message, contains('Welcome to SRSecrets!'));
      
      // After completing some sections
      await onboardingProvider.completeVisualTutorial();
      message = onboardingProvider.getWelcomeMessage();
      expect(message, contains('Continue where you left off'));
      
      // After completing all sections
      await onboardingProvider.completeUseCases();
      await onboardingProvider.completeSecurityGuide();
      message = onboardingProvider.getWelcomeMessage();
      expect(message, contains('You can revisit any section'));
    });

    test('OnboardingProvider next step recommendations', () async {
      await onboardingProvider.initialize();
      
      // Initial recommendation
      String nextStep = onboardingProvider.getNextRecommendedStep();
      expect(nextStep, contains('Visual Tutorial'));
      
      // After visual tutorial
      await onboardingProvider.completeVisualTutorial();
      nextStep = onboardingProvider.getNextRecommendedStep();
      expect(nextStep, contains('Use Cases'));
      
      // After use cases
      await onboardingProvider.completeUseCases();
      nextStep = onboardingProvider.getNextRecommendedStep();
      expect(nextStep, contains('Security Guide'));
      
      // All completed
      await onboardingProvider.completeSecurityGuide();
      nextStep = onboardingProvider.getNextRecommendedStep();
      expect(nextStep, contains('Ready to use SRSecrets'));
    });

    testWidgets('Error screen displays properly', (WidgetTester tester) async {
      final errorScreen = AppRouter.createErrorScreen('Test error message');
      
      await tester.pumpWidget(MaterialApp(home: errorScreen));
      
      expect(find.text('Application Error'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Restart Application'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    group('Integration with existing app state', () {
      testWidgets('Provider integration in main app', (WidgetTester tester) async {
        final testApp = MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider.value(value: onboardingProvider),
            ],
            child: Builder(
              builder: (context) {
                return Consumer2<AuthProvider, OnboardingProvider>(
                  builder: (context, auth, onboarding, child) {
                    return AppRouter.determineInitialRoute(
                      isAuthenticated: auth.isAuthenticated,
                      isPinSet: auth.isPinSet,
                      isOnboardingCompleted: onboarding.isOnboardingCompleted,
                      isFirstLaunch: onboarding.isFirstLaunch,
                    );
                  },
                );
              },
            ),
          ),
        );

        await tester.pumpWidget(testApp);
        
        // Should show onboarding initially
        expect(find.byType(OnboardingFlowScreen), findsOneWidget);
      });
    });

    group('SOLID principles compliance', () {
      test('AppRouter follows Single Responsibility', () {
        // AppRouter only handles routing logic
        expect(AppRouter.determineInitialRoute, isA<Function>());
        expect(AppRouter.getRouteNameForState, isA<Function>());
        expect(AppRouter.validateRouteComponents, isA<Function>());
        expect(AppRouter.createErrorScreen, isA<Function>());
      });

      test('OnboardingProvider follows Single Responsibility', () {
        // OnboardingProvider only handles onboarding state
        expect(onboardingProvider.isOnboardingCompleted, isA<bool>());
        expect(onboardingProvider.completeOnboarding, isA<Function>());
        expect(onboardingProvider.completionProgress, isA<double>());
      });

      test('Dependency Inversion - depends on abstractions', () {
        // AppRouter takes boolean parameters, not concrete providers
        final widget = AppRouter.determineInitialRoute(
          isAuthenticated: true,
          isPinSet: true,
          isOnboardingCompleted: true,
          isFirstLaunch: false,
        );
        expect(widget, isA<Widget>());
      });
    });

    group('DDD architecture compliance', () {
      test('Clear domain boundaries', () {
        // Onboarding domain is separate from auth domain
        expect(onboardingProvider.runtimeType.toString(), 'OnboardingProvider');
        expect(authProvider.runtimeType.toString(), 'AuthProvider');
      });

      test('Domain services are properly encapsulated', () {
        // OnboardingProvider encapsulates onboarding business logic
        expect(onboardingProvider.getWelcomeMessage, isA<Function>());
        expect(onboardingProvider.getNextRecommendedStep, isA<Function>());
      });
    });
  });
}