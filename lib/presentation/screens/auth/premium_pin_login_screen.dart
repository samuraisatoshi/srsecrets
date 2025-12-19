import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_pin_input.dart';
import '../../widgets/premium_security_card.dart';
import '../../widgets/security_badges.dart';
import '../../widgets/app_branding_logo.dart';

/// Premium PIN login screen matching Trezor/Ledger standards
class PremiumPinLoginScreen extends StatefulWidget {
  const PremiumPinLoginScreen({super.key});

  @override
  State<PremiumPinLoginScreen> createState() => _PremiumPinLoginScreenState();
}

class _PremiumPinLoginScreenState extends State<PremiumPinLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPinEntered(String pin) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.authenticate(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF0A0E1A),
                    const Color(0xFF141824),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE8ECF4),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Logo and branding
                        const AppBrandingLogo(),

                        const SizedBox(height: 48),
                        
                        // Main content card
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: authProvider.isLocked
                              ? _buildLockedCard(context, authProvider, isDark)
                              : _buildPinEntryCard(context, authProvider, isDark),
                        ),
                        
                        const SizedBox(height: 32),

                        // Security badges
                        const SecurityBadgesRow(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntryCard(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    return PremiumSecurityCard(
      isElevated: true,
      showSecurityBadge: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Enter PIN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Access your encrypted vault',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          PremiumPinInput(
            onCompleted: _onPinEntered,
            isLoading: authProvider.isLoading,
            errorMessage: authProvider.errorMessage,
          ),
          
          if (authProvider.failedAttempts > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.error.withValues(alpha: 0.1),
                    theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Security Alert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${authProvider.failedAttempts} failed attempts. '
                          '${5 - authProvider.failedAttempts} remaining before lockout.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedCard(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    return PremiumSecurityCard(
      isElevated: true,
      gradientColors: [
        theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        theme.colorScheme.error.withValues(alpha: 0.05),
      ],
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.lock_clock,
              size: 40,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Account Locked',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Too many failed attempts',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(authProvider.lockoutDuration),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                    fontFamily: 'monospace', // Use monospace for consistent digit width
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().checkAuthStatus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check Status'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }
}