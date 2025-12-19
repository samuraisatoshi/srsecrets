import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/premium_theme.dart';
import '../secrets/secrets_list_screen.dart';
import '../secrets/create_secret_screen.dart';
import '../secrets/reconstruct_secret_screen.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../settings/settings_screen.dart';

/// Premium home screen with Trezor/Ledger-inspired design
class PremiumHomeScreen extends StatefulWidget {
  const PremiumHomeScreen({super.key});

  @override
  State<PremiumHomeScreen> createState() => _PremiumHomeScreenState();
}

class _PremiumHomeScreenState extends State<PremiumHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _navAnimationController;
  late AnimationController _pageAnimationController;
  
  static const List<Widget> _pages = <Widget>[
    SecretsListScreen(),
    CreateSecretScreen(),
    ReconstructSecretScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _navAnimationController.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      _pageAnimationController.reverse().then((_) {
        setState(() {
          _selectedIndex = index;
        });
        _pageAnimationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Remove the local ChangeNotifierProvider - use the app-level provider instead
    return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final isDesktop = constraints.maxWidth >= 840;
          
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
                          const Color(0xFFEFF3F8),
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildPremiumAppBar(context, isDark),
                    Expanded(
                      child: isDesktop
                          ? _buildDesktopLayout(context, isDark)
                          : isTablet
                              ? _buildTabletLayout(context, isDark)
                              : _buildMobileLayout(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar:
                isTablet ? null : _buildPremiumBottomNav(context, isDark),
          );
        },
    );
  }

  Widget _buildPremiumAppBar(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141824).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF2A3142).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    PremiumTheme.getPremiumGradient(bounds),
                child: const Text(
                  'SRSecrets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Shamir\'s Secret Sharing',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // User menu
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showUserMenu(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1C2333).withValues(alpha: 0.5),
                            const Color(0xFF2A3142).withValues(alpha: 0.3),
                          ]
                        : [
                            const Color(0xFFE8ECF4).withValues(alpha: 0.5),
                            const Color(0xFFE2E8F0).withValues(alpha: 0.3),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _pageAnimationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _pageAnimationController,
              curve: Curves.easeOutCubic,
            )),
            child: _pages[_selectedIndex],
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Premium navigation rail
        AnimatedBuilder(
          animation: _navAnimationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _navAnimationController,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141824).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    ..._buildNavItems(context, isDark),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Content area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _pageAnimationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _pageAnimationController,
                  child: _pages[_selectedIndex],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Premium sidebar
        AnimatedBuilder(
          animation: _navAnimationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _navAnimationController,
                curve: Curves.easeOutCubic,
              )),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141824).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.9),
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    ..._buildNavItems(context, isDark, extended: true),
                    const Spacer(),
                    _buildSecurityStatus(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Main content with constraint
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Container(
                padding: const EdgeInsets.all(32),
                child: AnimatedBuilder(
                  animation: _pageAnimationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _pageAnimationController,
                      child: _pages[_selectedIndex],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavItems(BuildContext context, bool isDark,
      {bool extended = false}) {
    final theme = Theme.of(context);
    final items = [
      (Icons.folder_special, 'Secrets', 'View all secrets'),
      (Icons.add_circle, 'Create', 'Split new secret'),
      (Icons.restore, 'Reconstruct', 'Recover secret'),
    ];
    
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = _selectedIndex == index;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTapped(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 20 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.tertiary.withValues(alpha: 0.1),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.tertiary,
                              ],
                            )
                          : null,
                      color: !isSelected
                          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$1,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPremiumBottomNav(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141824)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.folder_special_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: ShaderMask(
              shaderCallback: (bounds) =>
                  PremiumTheme.getPremiumGradient(bounds),
              child: const Icon(
                Icons.folder_special,
                color: Colors.white,
              ),
            ),
            label: 'Secrets',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: ShaderMask(
              shaderCallback: (bounds) =>
                  PremiumTheme.getPremiumGradient(bounds),
              child: const Icon(
                Icons.add_circle,
                color: Colors.white,
              ),
            ),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.restore,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: ShaderMask(
              shaderCallback: (bounds) =>
                  PremiumTheme.getPremiumGradient(bounds),
              child: const Icon(
                Icons.restore,
                color: Colors.white,
              ),
            ),
            label: 'Reconstruct',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatus(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All systems operational',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            decoration: PremiumTheme.getPremiumCard(
              isDark: isDark,
              isElevated: true,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'User Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openSettings(context);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showOnboardingAgain(context);
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('View Onboarding'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showLogoutConfirmation(context);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 360,
            decoration: PremiumTheme.getPremiumCard(
              isDark: isDark,
              isElevated: true,
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout? You will need to enter your PIN to access your secrets again.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthProvider>().logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOnboardingAgain(BuildContext context) {
    final onboardingProvider = context.read<OnboardingProvider>();
    onboardingProvider.resetOnboardingState();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingFlowScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }
}