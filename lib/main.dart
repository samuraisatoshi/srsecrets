import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/secret_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/theme/premium_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(const SRSecretsApp());
}

class SRSecretsApp extends StatelessWidget {
  const SRSecretsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SecretProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => OnboardingProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SRSecrets',
        theme: PremiumTheme.getLightTheme(),
        darkTheme: PremiumTheme.getDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize providers on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
      context.read<OnboardingProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OnboardingProvider>(
      builder: (context, authProvider, onboardingProvider, child) {
        // Show loading while providers initialize
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Validate route components
        if (!AppRouter.validateRouteComponents()) {
          return AppRouter.createErrorScreen(
            'Application components validation failed. Please restart the app.',
          );
        }

        // Use router to determine initial route
        return AppRouter.determineInitialRoute(
          isAuthenticated: authProvider.isAuthenticated,
          isPinSet: authProvider.isPinSet,
          isOnboardingCompleted: onboardingProvider.isOnboardingCompleted,
          isFirstLaunch: onboardingProvider.isFirstLaunch,
        );
      },
    );
  }
}