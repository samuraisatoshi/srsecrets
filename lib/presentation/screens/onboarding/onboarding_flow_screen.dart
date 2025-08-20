import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/premium_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../auth/premium_pin_setup_screen.dart';
import '../auth/premium_pin_login_screen.dart';
import '../home/premium_home_screen.dart';
import 'onboarding_screen.dart';
import 'use_cases_screen.dart';
import 'security_guide_screen.dart';

/// Master onboarding flow combining visual education, use cases, and security guide
/// Provides comprehensive user education before entering the main application
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late PageController _mainPageController;
  late AnimationController _transitionController;
  late AnimationController _fabController;
  
  int _currentMainIndex = 0;
  bool _showFloatingActions = false;

  final List<OnboardingFlow> _onboardingFlows = [
    OnboardingFlow(
      title: 'Visual Tutorial',
      subtitle: 'Learn the basics',
      icon: Icons.play_circle_filled,
      color: Color(0xFF4B7BEC),
      screen: OnboardingScreen(),
    ),
    OnboardingFlow(
      title: 'Real Use Cases',
      subtitle: 'See practical applications',
      icon: Icons.business_center,
      color: Color(0xFF00D395),
      screen: UseCasesScreen(),
    ),
    OnboardingFlow(
      title: 'Security Guide',
      subtitle: 'Professional best practices',
      icon: Icons.security,
      color: Color(0xFF6C5CE7),
      screen: SecurityGuideScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mainPageController = PageController();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _transitionController.forward();
    
    // Show floating actions after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFloatingActions = true;
        });
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainPageController.dispose();
    _transitionController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _navigateToFlow(int index) {
    // Mark previous section as completed
    _markCurrentSectionComplete();
    
    setState(() {
      _currentMainIndex = index;
    });
    _mainPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
    _transitionController.reset();
    _transitionController.forward();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _markCurrentSectionComplete() {
    final onboardingProvider = context.read<OnboardingProvider>();
    
    switch (_currentMainIndex) {
      case 0: // Visual Tutorial
        onboardingProvider.completeVisualTutorial();
        break;
      case 1: // Use Cases
        onboardingProvider.completeUseCases();
        break;
      case 2: // Security Guide
        onboardingProvider.completeSecurityGuide();
        break;
    }
  }

  void _skipOnboarding() {
    final onboardingProvider = context.read<OnboardingProvider>();
    final authProvider = context.read<AuthProvider>();
    
    onboardingProvider.skipOnboarding();
    
    // Navigate based on auth status  
    if (authProvider.isPinSet && authProvider.isAuthenticated) {
      // User already has PIN and is authenticated, return to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumHomeScreen(),
        ),
      );
    } else if (authProvider.isPinSet) {
      // PIN is set but not authenticated, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumPinLoginScreen(),
        ),
      );
    } else {
      // No PIN set, go to PIN setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumPinSetupScreen(),
        ),
      );
    }
  }

  void _completeOnboarding() {
    // Mark current section as complete before finishing
    _markCurrentSectionComplete();
    
    final onboardingProvider = context.read<OnboardingProvider>();
    final authProvider = context.read<AuthProvider>();
    
    onboardingProvider.completeOnboarding();
    
    // Navigate based on auth status
    if (authProvider.isPinSet && authProvider.isAuthenticated) {
      // User already has PIN and is authenticated, return to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumHomeScreen(),
        ),
      );
    } else if (authProvider.isPinSet) {
      // PIN is set but not authenticated, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumPinLoginScreen(),
        ),
      );
    } else {
      // No PIN set, go to PIN setup
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PremiumPinSetupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          PageView.builder(
            controller: _mainPageController,
            onPageChanged: (index) {
              setState(() {
                _currentMainIndex = index;
              });
              _transitionController.reset();
              _transitionController.forward();
            },
            itemCount: _onboardingFlows.length,
            itemBuilder: (context, index) {
              return _onboardingFlows[index].screen;
            },
          ),
          
          // Top navigation bar
          if (!isTablet) _buildMobileTopNav(theme, isDark),
          
          // Desktop/tablet navigation sidebar
          if (isTablet) _buildTabletSidebar(theme, isDark),
          
          // Floating action buttons - disabled to prevent content blocking
          // if (_showFloatingActions && !isTablet) _buildFloatingActions(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileTopNav(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _transitionController.value)),
          child: Opacity(
            opacity: _transitionController.value,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flow navigation buttons (clickable progress indicators)
                    Row(
                      children: _onboardingFlows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final flow = entry.value;
                        final isActive = index == _currentMainIndex;
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToFlow(index),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      flow.icon,
                                      size: 16,
                                      color: isActive ? flow.color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 4),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: flow.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    // Skip button
                    TextButton(
                      onPressed: _skipOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletSidebar(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-200 * (1 - _transitionController.value), 0),
          child: Opacity(
            opacity: _transitionController.value,
            child: SafeArea(
              child: Container(
                width: 280,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: PremiumTheme.getGlassMorphism(isDark: isDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _onboardingFlows[_currentMainIndex].color,
                                _onboardingFlows[_currentMainIndex].color.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learn SRSecrets',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Interactive education',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Navigation items
                    Expanded(
                      child: Column(
                        children: _onboardingFlows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final flow = entry.value;
                          final isActive = index == _currentMainIndex;
                          
                          return _buildNavigationItem(
                            flow,
                            isActive,
                            () => _navigateToFlow(index),
                            theme,
                            isDark,
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Action buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _completeOnboarding,
                            icon: const Icon(Icons.rocket_launch),
                            label: const Text('Start Using App'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _onboardingFlows[_currentMainIndex].color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _skipOnboarding,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Skip Tutorial'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationItem(
    OnboardingFlow flow,
    bool isActive,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        flow.color.withValues(alpha: 0.2),
                        flow.color.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: flow.color.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              flow.color,
                              flow.color.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: !isActive
                        ? theme.colorScheme.surfaceContainer
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    flow.icon,
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flow.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? flow.color
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        flow.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabController.value,
          child: Opacity(
            opacity: _fabController.value,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 120, right: 20),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flow navigation buttons
                  ..._onboardingFlows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final flow = entry.value;
                    final isActive = index == _currentMainIndex;

                    if (isActive) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton.small(
                        onPressed: () => _navigateToFlow(index),
                        heroTag: 'fab_$index',
                        backgroundColor: flow.color,
                        child: Icon(
                          flow.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 20),
                  
                  // Main action button
                  FloatingActionButton.extended(
                    onPressed: _completeOnboarding,
                    heroTag: 'fab_main',
                    backgroundColor: _onboardingFlows[_currentMainIndex].color,
                    icon: const Icon(Icons.rocket_launch, color: Colors.white),
                    label: const Text(
                      'Get Started',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
                ),
            ),
          ),
        );
      },
    );
  }
}

// Data Model
class OnboardingFlow {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  OnboardingFlow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}