import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/secret_provider.dart';
import 'presentation/screens/auth/premium_pin_setup_screen.dart';
import 'presentation/screens/auth/premium_pin_login_screen.dart';
import 'presentation/screens/home/premium_home_screen.dart';
import 'presentation/theme/premium_theme.dart';

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
    // Check authentication status on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isPinSet) {
          return const PremiumPinSetupScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const PremiumPinLoginScreen();
        }

        return const PremiumHomeScreen();
      },
    );
  }
}