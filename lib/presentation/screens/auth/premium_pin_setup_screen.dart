import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_pin_input.dart';
import '../../widgets/premium_security_card.dart';
import '../../theme/premium_theme.dart';

/// Premium PIN setup screen matching Trezor/Ledger standards
class PremiumPinSetupScreen extends StatefulWidget {
  const PremiumPinSetupScreen({super.key});

  @override
  State<PremiumPinSetupScreen> createState() => _PremiumPinSetupScreenState();
}

class _PremiumPinSetupScreenState extends State<PremiumPinSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  final PageController _pageController = PageController();

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
    _pageController.dispose();
    super.dispose();
  }

  void _onPinEntered(String pin) {
    if (!_isConfirming) {
      setState(() {
        _pin = pin;
        _isConfirming = true;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _confirmPin = pin;
      });
      _setupPin();
    }
  }

  Future<void> _setupPin() async {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PINs do not match. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _resetSetup();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.setupPin(_pin);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to setup PIN'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _resetSetup();
    }
  }

  void _resetSetup() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isConfirming = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildSetupPage(context, isDark),
                      _buildConfirmPage(context, isDark),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSetupPage(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Logo and branding
          _buildLogo(context, isDark),
          
          const SizedBox(height: 48),
          
          // Setup card
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: PremiumSecurityCard(
              isElevated: true,
              showSecurityBadge: true,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Your PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure your vault with a strong PIN',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  PremiumPinInput(
                    onCompleted: _onPinEntered,
                    isLoading: authProvider.isLoading,
                    isSetupMode: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Security info
          _buildSecurityInfo(context, isDark),
        ],
      ),
    );
  }

  Widget _buildConfirmPage(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Logo and branding
          _buildLogo(context, isDark),
          
          const SizedBox(height: 48),
          
          // Confirm card
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: PremiumSecurityCard(
              isElevated: true,
              showSecurityBadge: true,
              gradientColors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                theme.colorScheme.primary.withValues(alpha: 0.05),
              ],
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirm Your PIN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your PIN again to confirm',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  PremiumPinInput(
                    onCompleted: _onPinEntered,
                    isLoading: authProvider.isLoading,
                    isSetupMode: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  TextButton.icon(
                    onPressed: authProvider.isLoading ? null : _resetSetup,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Start Over'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield,
            size: 56,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => PremiumTheme.getPremiumGradient(bounds),
          child: const Text(
            'SRSecrets',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome to Hardware-Grade Security',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'PIN Security Requirements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirement(context, 'Use 4-8 digits for your PIN'),
          _buildRequirement(context, 'Avoid sequential numbers (1234, 5678)'),
          _buildRequirement(context, 'Avoid repeated digits (1111, 0000)'),
          _buildRequirement(context, 'Choose a PIN you can remember'),
          _buildRequirement(context, 'Your PIN encrypts all operations'),
        ],
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, String text) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}