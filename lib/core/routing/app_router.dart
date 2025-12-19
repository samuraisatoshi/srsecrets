import 'package:flutter/material.dart';
import '../../presentation/screens/onboarding/onboarding_flow_screen.dart';
import '../../presentation/screens/auth/premium_pin_setup_screen.dart';
import '../../presentation/screens/auth/premium_pin_login_screen.dart';
import '../../presentation/screens/home/premium_home_screen.dart';

/// Application Router following SOLID principles
/// Single responsibility: Route determination and navigation
/// Open/closed: Extensible for new routes without modifying existing logic
/// Dependency inversion: Depends on abstractions (route states) not implementations
class AppRouter {
  /// Determine initial route based on application state
  ///
  /// Flow:
  /// 1. First launch/onboarding incomplete -> Onboarding
  /// 2. Already authenticated with PIN set -> Home (handles race condition during setup)
  /// 3. User hasn't seen PIN setup -> PIN Setup (with skip option)
  /// 4. PIN not required -> Home
  /// 5. PIN required but not set -> PIN Setup
  /// 6. PIN required and set but not authenticated -> PIN Login
  /// 7. Otherwise -> Home
  static Widget determineInitialRoute({
    required bool isAuthenticated,
    required bool isPinSet,
    required bool isOnboardingCompleted,
    required bool isFirstLaunch,
    bool isPinRequired = false,
    bool hasSeenPinSetup = false,
  }) {
    // Debug logging for routing decisions
    print('[AppRouter] Route decision: isAuth=$isAuthenticated, isPinSet=$isPinSet, '
        'onboardingComplete=$isOnboardingCompleted, firstLaunch=$isFirstLaunch, '
        'pinRequired=$isPinRequired, seenPinSetup=$hasSeenPinSetup');

    // Route determination logic follows clear precedence rules

    // 1. First launch or incomplete onboarding -> Onboarding Flow
    if (isFirstLaunch || !isOnboardingCompleted) {
      print('[AppRouter] -> OnboardingFlowScreen (first launch or onboarding incomplete)');
      return const OnboardingFlowScreen();
    }

    // 2. If user just completed PIN setup (authenticated + isPinSet), go to Home
    // This handles the race condition where setupPin calls notifyListeners()
    // before setPinRequired(true) is called, avoiding the PIN setup loop
    if (isAuthenticated && isPinSet) {
      print('[AppRouter] -> PremiumHomeScreen (authenticated with PIN set)');
      return const PremiumHomeScreen();
    }

    // 3. User hasn't made PIN decision yet -> Show PIN Setup with Skip option
    if (!hasSeenPinSetup) {
      print('[AppRouter] -> PremiumPinSetupScreen (hasnt seen PIN setup)');
      return const PremiumPinSetupScreen();
    }

    // 4. If PIN is not required, skip PIN login entirely
    if (!isPinRequired) {
      print('[AppRouter] -> PremiumHomeScreen (PIN not required)');
      return const PremiumHomeScreen();
    }

    // 5. PIN required but not configured -> PIN Setup
    if (!isPinSet) {
      print('[AppRouter] -> PremiumPinSetupScreen (PIN required but not set)');
      return const PremiumPinSetupScreen();
    }

    // 6. PIN configured but not authenticated -> PIN Login
    if (!isAuthenticated) {
      print('[AppRouter] -> PremiumPinLoginScreen (needs authentication)');
      return const PremiumPinLoginScreen();
    }

    // 7. Fully authenticated -> Main Application
    print('[AppRouter] -> PremiumHomeScreen (fully authenticated)');
    return const PremiumHomeScreen();
  }

  /// Get route name for current state (useful for analytics/debugging)
  static String getRouteNameForState({
    required bool isAuthenticated,
    required bool isPinSet,
    required bool isOnboardingCompleted,
    required bool isFirstLaunch,
    bool isPinRequired = false,
    bool hasSeenPinSetup = false,
  }) {
    if (isFirstLaunch || !isOnboardingCompleted) {
      return '/onboarding';
    }
    if (isAuthenticated && isPinSet) {
      return '/home';
    }
    if (!hasSeenPinSetup) {
      return '/pin-setup';
    }
    if (!isPinRequired) {
      return '/home';
    }
    if (!isPinSet) {
      return '/pin-setup';
    }
    if (!isAuthenticated) {
      return '/pin-login';
    }
    return '/home';
  }

  /// Create error fallback screen
  static Widget createErrorScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Application Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Force app restart by throwing handled error
                  throw StateError('User requested app restart');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart Application'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validate that all required screens are available
  static bool validateRouteComponents() {
    try {
      // Test instantiation of core screens to ensure they're available
      // These variables ensure the constructors can be called without errors
      OnboardingFlowScreen();
      PremiumPinSetupScreen();
      PremiumPinLoginScreen();
      PremiumHomeScreen();
      
      // If we got here, all screens can be instantiated
      return true;
    } catch (e) {
      return false;
    }
  }
}