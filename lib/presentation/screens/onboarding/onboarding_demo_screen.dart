import 'package:flutter/material.dart';
import '../../theme/premium_theme.dart';
import 'onboarding_flow_screen.dart';

/// Demo screen showcasing the onboarding system features
/// This screen demonstrates the visual onboarding capabilities to stakeholders
class OnboardingDemoScreen extends StatefulWidget {
  const OnboardingDemoScreen({super.key});

  @override
  State<OnboardingDemoScreen> createState() => _OnboardingDemoScreenState();
}

class _OnboardingDemoScreenState extends State<OnboardingDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _cardController;
  
  final List<OnboardingFeature> _features = [
    OnboardingFeature(
      title: 'Visual Tutorial System',
      description: 'Four interactive screens with hero animations teaching Shamir\'s Secret Sharing fundamentals',
      icon: Icons.play_circle_filled,
      color: Color(0xFF4B7BEC),
      highlights: [
        'Hero animations and visual comparisons',
        'Interactive security demonstrations',
        'Step-by-step cryptographic education',
        'Compelling imagery and illustrations',
      ],
      estimatedTime: '16 hours',
      complexity: 'High',
    ),
    OnboardingFeature(
      title: 'Business & Personal Cases',
      description: 'Real-world scenarios showing practical applications across different user segments',
      icon: Icons.business_center,
      color: Color(0xFF00D395),
      highlights: [
        'Interactive business scenario walkthroughs',
        'Personal security use case demonstrations',
        'Enterprise compliance examples',
        'Risk reduction visualizations',
      ],
      estimatedTime: '20 hours',
      complexity: 'High',
    ),
    OnboardingFeature(
      title: 'Security Best Practices',
      description: 'Professional-grade security guidance with interactive resources and recommendations',
      icon: Icons.security,
      color: Color(0xFF6C5CE7),
      highlights: [
        'Storage recommendation system',
        'Interactive security scoring',
        'Professional best practices guide',
        'Compliance and audit guidelines',
      ],
      estimatedTime: '12 hours',
      complexity: 'Medium',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _launchOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OnboardingFlowScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding System Demo'),
        actions: [
          TextButton.icon(
            onPressed: _launchOnboarding,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Launch Demo'),
          ),
          const SizedBox(width: 16),
        ],
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 32),
                _buildFeaturesGrid(theme, isDark, size),
                const SizedBox(height: 32),
                _buildTechnicalSpecs(theme, isDark),
                const SizedBox(height: 32),
                _buildDesignPrinciples(theme, isDark),
                const SizedBox(height: 32),
                _buildLaunchSection(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _slideController.value)),
          child: Opacity(
            opacity: _slideController.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: PremiumTheme.getPremiumCard(
                isDark: isDark,
                isElevated: true,
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4B7BEC),
                          Color(0xFF6C5CE7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Onboarding & Visual Education System',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comprehensive user education system with interactive visuals, real-world use cases, and professional security guidance. Designed following Material Design 3 and accessibility standards.',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildMetricChip('3 Screens', Icons.layers, theme),
                            const SizedBox(width: 12),
                            _buildMetricChip('48h Estimate', Icons.schedule, theme),
                            const SizedBox(width: 12),
                            _buildMetricChip('WCAG 2.1 AA', Icons.accessibility, theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricChip(String label, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B7BEC).withValues(alpha: 0.1),
            Color(0xFF6C5CE7).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF4B7BEC).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Color(0xFF4B7BEC),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(ThemeData theme, bool isDark, Size size) {
    final crossAxisCount = size.width > 1200 ? 3 : size.width > 800 ? 2 : 1;
    
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            final delay = index * 0.2;
            
            return Transform.translate(
              offset: Offset(
                0,
                50 * (1 - Curves.easeOutCubic.transform(
                  (_cardController.value - delay).clamp(0.0, 1.0)
                )),
              ),
              child: Opacity(
                opacity: Curves.easeOutCubic.transform(
                  (_cardController.value - delay).clamp(0.0, 1.0)
                ),
                child: _buildFeatureCard(feature, theme, isDark),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(OnboardingFeature feature, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.getPremiumCard(
        isDark: isDark,
        isElevated: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      feature.color,
                      feature.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  feature.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: feature.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature.estimatedTime,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: feature.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getComplexityColor(feature.complexity).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature.complexity,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getComplexityColor(feature.complexity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Key Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...feature.highlights.map((highlight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        feature.color,
                        feature.color.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    highlight,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTechnicalSpecs(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.getPremiumCard(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4B7BEC), Color(0xFF6C5CE7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.code,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Technical Implementation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildTechSpec('Flutter Framework', 'Material Design 3', Icons.phone_android),
              _buildTechSpec('Responsive Design', 'Mobile/Tablet/Desktop', Icons.devices),
              _buildTechSpec('Animations', 'Hero & Transition Effects', Icons.animation),
              _buildTechSpec('Accessibility', 'WCAG 2.1 AA Compliant', Icons.accessibility),
              _buildTechSpec('State Management', 'Provider Pattern', Icons.settings),
              _buildTechSpec('Theme Support', 'Light/Dark Modes', Icons.palette),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechSpec(String title, String description, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B7BEC).withValues(alpha: 0.1),
            Color(0xFF6C5CE7).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF4B7BEC).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Color(0xFF4B7BEC),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignPrinciples(ThemeData theme, bool isDark) {
    final principles = [
      'Security-focused visual language',
      'Progressive disclosure of complex concepts',
      'Interactive learning elements',
      'Professional hardware wallet inspiration',
      'Clear visual hierarchy',
      'Consistent animation patterns',
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.getPremiumCard(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00D395), Color(0xFF4B7BEC)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.design_services,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Design Principles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: principles.length,
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00D395), Color(0xFF4B7BEC)],
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
                      principles[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchSection(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4B7BEC).withValues(alpha: 0.1),
            Color(0xFF6C5CE7).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF4B7BEC).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Experience the Onboarding Flow',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Interact with the complete user education system including visual tutorials, use case demonstrations, and security best practices.',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            onPressed: _launchOnboarding,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Launch Interactive Demo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B7BEC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Model
class OnboardingFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> highlights;
  final String estimatedTime;
  final String complexity;

  OnboardingFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.highlights,
    required this.estimatedTime,
    required this.complexity,
  });
}