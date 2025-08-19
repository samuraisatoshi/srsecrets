import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/premium_theme.dart';

/// Fullscreen visual onboarding with hero animations
/// Educates users about Shamir's Secret Sharing in 4 compelling screens
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _heroAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _particleAnimationController;
  
  int _currentPage = 0;
  
  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: 'Secure Your Secrets',
      subtitle: 'Bank-grade cryptography meets simplicity',
      description: 'Split your most sensitive information into encrypted shares using Shamir\'s Secret Sharing algorithm - the same technology trusted by cryptocurrency hardware wallets.',
      heroIcon: Icons.security,
      accentColor: Color(0xFF4B7BEC),
      benefits: [
        'Military-grade encryption',
        'Zero network dependency',
        'Cryptographically proven security',
      ],
    ),
    OnboardingData(
      title: 'Split & Distribute',
      subtitle: 'Your secret becomes multiple encrypted shares',
      description: 'Transform your password, recovery phrase, or confidential data into multiple encrypted shares. Each share is mathematically useless without the others.',
      heroIcon: Icons.call_split,
      accentColor: Color(0xFF00D395),
      benefits: [
        'Configurable threshold (3 of 5, 2 of 3, etc.)',
        'Each share is individually secure',
        'No single point of failure',
      ],
    ),
    OnboardingData(
      title: 'Store Safely',
      subtitle: 'Distribute shares across secure locations',
      description: 'Place each encrypted share in a different secure location - safety deposit boxes, trusted family members, or secure cloud storage.',
      heroIcon: Icons.shield_outlined,
      accentColor: Color(0xFF6C5CE7),
      benefits: [
        'Geographic distribution recommended',
        'Multiple storage medium options',
        'Redundancy prevents total loss',
      ],
    ),
    OnboardingData(
      title: 'Recover Instantly',
      subtitle: 'Reconstruct your secret when needed',
      description: 'Collect the minimum required shares to instantly reconstruct your original secret. The mathematical precision ensures perfect recovery every time.',
      heroIcon: Icons.restore,
      accentColor: Color(0xFFFF6B6B),
      benefits: [
        'Instant reconstruction',
        'Perfect accuracy guaranteed',
        'Works even if some shares are lost',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    // Start animations
    _heroAnimationController.forward();
    _contentAnimationController.forward();
    _particleAnimationController.repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroAnimationController.dispose();
    _contentAnimationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _currentPage++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _restartAnimations();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _heroAnimationController.reset();
    _contentAnimationController.reset();
    _heroAnimationController.forward();
    _contentAnimationController.forward();
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed('/pin-setup');
  }

  void _skipOnboarding() {
    Navigator.of(context).pushReplacementNamed('/pin-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    const Color(0xFF1C2333),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFEFF3F8),
                    const Color(0xFFE8ECF4),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            _buildAnimatedBackground(isDark, size),
            
            // Main content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _restartAnimations();
              },
              itemCount: _onboardingPages.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(
                  context,
                  _onboardingPages[index],
                  isDark,
                  size,
                );
              },
            ),
            
            // Top navigation bar
            _buildTopNavigation(context, isDark),
            
            // Bottom navigation
            _buildBottomNavigation(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _particleAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: ParticlesPainter(
            animation: _particleAnimationController,
            isDark: isDark,
            accentColor: _onboardingPages[_currentPage].accentColor,
          ),
        );
      },
    );
  }

  Widget _buildTopNavigation(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Progress indicator
            Row(
              children: List.generate(
                _onboardingPages.length,
                (index) => _buildProgressDot(index, theme, isDark),
              ),
            ),
            
            // Skip button
            TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index, ThemeData theme, bool isDark) {
    final isActive = index == _currentPage;
    final isPrevious = index < _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive || isPrevious
            ? LinearGradient(
                colors: [
                  _onboardingPages[_currentPage].accentColor,
                  _onboardingPages[_currentPage].accentColor.withValues(alpha: 0.6),
                ],
              )
            : null,
        color: !isActive && !isPrevious
            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
            : null,
      ),
    );
  }

  Widget _buildOnboardingPage(
    BuildContext context,
    OnboardingData data,
    bool isDark,
    Size size,
  ) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 80), // Space for top navigation
            
            // Hero section with animated icon
            Expanded(
              flex: 3,
              child: _buildHeroSection(data, theme, isDark, size),
            ),
            
            // Content section
            Expanded(
              flex: 2,
              child: _buildContentSection(data, theme, isDark),
            ),
            
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(OnboardingData data, ThemeData theme, bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _heroAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            50 * (1 - _heroAnimationController.value),
          ),
          child: Opacity(
            opacity: _heroAnimationController.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main hero icon with gradient background
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        data.accentColor.withValues(alpha: 0.2),
                        data.accentColor.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          data.accentColor,
                          data.accentColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.accentColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      data.heroIcon,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Visual comparison or illustration
                _buildVisualComparison(data, theme, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisualComparison(OnboardingData data, ThemeData theme, bool isDark) {
    if (_currentPage == 0) {
      return _buildSecurityComparison(theme, isDark);
    } else if (_currentPage == 1) {
      return _buildSplittingVisualization(theme, isDark);
    } else if (_currentPage == 2) {
      return _buildDistributionVisualization(theme, isDark);
    } else {
      return _buildReconstructionVisualization(theme, isDark);
    }
  }

  Widget _buildSecurityComparison(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildComparisonCard(
          'Traditional Storage',
          Icons.key,
          Colors.red.withValues(alpha: 0.3),
          'Single point of failure',
          false,
          theme,
          isDark,
        ),
        Container(
          width: 40,
          height: 2,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        _buildComparisonCard(
          'Shamir\'s Sharing',
          Icons.shield,
          Colors.green.withValues(alpha: 0.3),
          'Mathematically secure',
          true,
          theme,
          isDark,
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    String title,
    IconData icon,
    Color backgroundColor,
    String subtitle,
    bool isPositive,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: 120,
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isPositive ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSplittingVisualization(ThemeData theme, bool isDark) {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Original secret
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description,
              color: Colors.white,
              size: 32,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Arrow
          Icon(
            Icons.arrow_forward,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          
          const SizedBox(width: 16),
          
          // Shares
          Column(
            children: [
              Row(
                children: List.generate(3, (index) => 
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: _onboardingPages[1].accentColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(2, (index) => 
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: _onboardingPages[1].accentColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionVisualization(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center share
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _onboardingPages[2].accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          // Distributed shares
          ...List.generate(5, (index) {
            final angle = (index * 72) * (3.14159 / 180); // 72 degrees apart
            final radius = 60.0;
            final x = radius * math.cos(angle);
            final y = radius * math.sin(angle);
            
            return Transform.translate(
              offset: Offset(x, y),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _onboardingPages[2].accentColor.withValues(alpha: 0.8),
                      _onboardingPages[2].accentColor.withValues(alpha: 0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getLocationIcon(index),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getLocationIcon(int index) {
    switch (index) {
      case 0: return Icons.home;
      case 1: return Icons.account_balance;
      case 2: return Icons.cloud;
      case 3: return Icons.family_restroom;
      case 4: return Icons.safety_check;
      default: return Icons.place;
    }
  }

  Widget _buildReconstructionVisualization(ThemeData theme, bool isDark) {
    return Container(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Required shares
          Column(
            children: [
              Row(
                children: List.generate(3, (index) => 
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _onboardingPages[3].accentColor,
                          _onboardingPages[3].accentColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3 of 5 shares',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // Arrow
          Icon(
            Icons.arrow_forward,
            color: theme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          
          const SizedBox(width: 20),
          
          // Reconstructed secret
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green,
                  Colors.green.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(OnboardingData data, ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - _contentAnimationController.value),
          ),
          child: Opacity(
            opacity: _contentAnimationController.value,
            child: Column(
              children: [
                // Title and subtitle
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      data.accentColor,
                      data.accentColor.withValues(alpha: 0.8),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    data.subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Benefits list
                ...data.benefits.map((benefit) => _buildBenefitItem(
                  benefit,
                  data.accentColor,
                  theme,
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(String benefit, Color accentColor, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              if (_currentPage > 0)
                OutlinedButton.icon(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              else
                const SizedBox(width: 100), // Placeholder for alignment
              
              // Next/Get Started button
              ElevatedButton.icon(
                onPressed: _nextPage,
                icon: Icon(_currentPage == _onboardingPages.length - 1
                    ? Icons.rocket_launch
                    : Icons.arrow_forward),
                label: Text(_currentPage == _onboardingPages.length - 1
                    ? 'Get Started'
                    : 'Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  backgroundColor: _onboardingPages[_currentPage].accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: _onboardingPages[_currentPage].accentColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for onboarding pages
class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData heroIcon;
  final Color accentColor;
  final List<String> benefits;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.heroIcon,
    required this.accentColor,
    required this.benefits,
  });
}

/// Custom painter for animated background particles
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;
  final Color accentColor;

  ParticlesPainter({
    required this.animation,
    required this.isDark,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;

    // Generate floating particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + i * 0.1) % 1.0;
      final x = (i * 37.0) % size.width;
      final y = size.height * progress;
      final opacity = (1.0 - progress) * 0.3;
      
      paint.color = accentColor.withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        2.0 + (progress * 3.0),
        paint,
      );
    }

    // Generate connecting lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    paint.color = accentColor.withValues(alpha: 0.1);

    for (int i = 0; i < 10; i++) {
      final startX = (i * 67.0) % size.width;
      final startY = (animation.value * size.height + i * 40) % size.height;
      final endX = ((i + 1) * 67.0) % size.width;
      final endY = ((animation.value + 0.1) * size.height + (i + 1) * 40) % size.height;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
           accentColor != oldDelegate.accentColor;
  }
}