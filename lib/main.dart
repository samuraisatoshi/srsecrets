import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/secret_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'domains/i18n/providers/i18n_provider.dart';
import 'presentation/theme/premium_theme.dart';
import 'core/routing/app_router.dart';
import 'l10n/app_localizations.dart';

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
          create: (context) => I18nProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SecretProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => OnboardingProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(),
        ),
      ],
      child: Consumer<I18nProvider>(
        builder: (context, i18nProvider, child) {
          return MaterialApp(
            title: 'SRSecrets',
            locale: i18nProvider.getFlutterLocale(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: I18nProvider.getSupportedFlutterLocales(),
            theme: PremiumTheme.getLightTheme(),
            darkTheme: PremiumTheme.getDarkTheme(),
            themeMode: ThemeMode.system,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
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
      context.read<I18nProvider>().initialize();
      context.read<AuthProvider>().checkAuthStatus();
      context.read<OnboardingProvider>().initialize();
      context.read<SettingsProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, OnboardingProvider, I18nProvider, SettingsProvider>(
      builder: (context, authProvider, onboardingProvider, i18nProvider, settingsProvider, child) {
        // Show loading while providers initialize
        if (authProvider.isLoading || i18nProvider.isLoading || settingsProvider.isLoading) {
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
          isPinRequired: settingsProvider.isPinRequired,
          hasSeenPinSetup: settingsProvider.hasSeenPinSetup,
        );
      },
    );
  }
}