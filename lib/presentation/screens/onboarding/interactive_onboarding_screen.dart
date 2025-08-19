import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/wireframe_overlay_system.dart';
import '../../widgets/crypto_tutorial_animations.dart';
import '../../widgets/practice_mode_system.dart';
import '../../theme/premium_theme.dart';

/// Interactive Onboarding Screen
/// Integrates wireframe overlay, crypto tutorials, and practice mode
/// Provides comprehensive hands-on learning experience
class InteractiveOnboardingScreen extends StatefulWidget {
  const InteractiveOnboardingScreen({super.key});

  @override
  State<InteractiveOnboardingScreen> createState() => _InteractiveOnboardingScreenState();
}

class _InteractiveOnboardingScreenState extends State<InteractiveOnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late TabController _tabController;
  
  int _currentTabIndex = 0;
  bool _wireframeActive = false;
  bool _tutorialCompleted = false;
  bool _practiceCompleted = false;

  // Global keys for wireframe targeting
  final GlobalKey _tutorialTabKey = GlobalKey();
  final GlobalKey _practiceTabKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _transitionController.forward();
  }

  void _toggleWireframeMode() {
    setState(() {
      _wireframeActive = !_wireframeActive;
    });
    HapticFeedback.mediumImpact();
  }

  void _onTutorialComplete() {
    setState(() {
      _tutorialCompleted = true;
    });
    _showCompletionFeedback('Tutorial completed! 🎉');
  }

  void _onPracticeComplete() {
    setState(() {
      _practiceCompleted = true;
    });
    _showCompletionFeedback('Practice session completed! 🏆');
  }

  void _showCompletionFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed('/pin-setup');
  }

  List<WireframeElement> _getWireframeElements() {
    return [
      WireframeElement(
        id: 'welcome',
        title: 'Welcome to Interactive Learning',
        description: 'This is your hands-on learning environment for Shamir\'s Secret Sharing.',
        icon: Icons.school,
        color: const Color(0xFF4B7BEC),
        type: WireframeType.spotlight,
      ),
      WireframeElement(
        id: 'tutorials',
        title: 'Animation Tutorials',
        description: 'Learn with interactive animations and visual demonstrations.',
        targetKey: _tutorialTabKey,
        icon: Icons.play_circle_filled,
        color: const Color(0xFF00D395),
        type: WireframeType.highlight,
        arrowDirection: ArrowDirection.up,
      ),
      WireframeElement(
        id: 'practice',
        title: 'Practice Mode',
        description: 'Apply your knowledge with hands-on practice using sample data.',
        targetKey: _practiceTabKey,
        icon: Icons.psychology,
        color: const Color(0xFF6C5CE7),
        type: WireframeType.highlight,
        arrowDirection: ArrowDirection.up,
      ),
      WireframeElement(
        id: 'help',
        title: 'Get Help',
        description: 'Toggle wireframe mode anytime for guidance and tips.',
        targetKey: _helpKey,
        icon: Icons.help_outline,
        color: const Color(0xFFFF6B6B),
        type: WireframeType.pulse,
        arrowDirection: ArrowDirection.down,
      ),
    ];
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WireframeOverlaySystem(
      isActive: _wireframeActive,
      elements: _getWireframeElements(),
      onComplete: () => setState(() => _wireframeActive = false),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interactive Learning'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              key: _settingsKey,
              onPressed: () => _showSettingsBottomSheet(context),
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
            ),
            IconButton(
              key: _helpKey,
              onPressed: _toggleWireframeMode,
              icon: Icon(_wireframeActive 
                  ? Icons.visibility_off_outlined 
                  : Icons.visibility_outlined),
              tooltip: _wireframeActive ? 'Hide Guide' : 'Show Guide',
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                key: GlobalKey(),
                icon: const Icon(Icons.info_outline),
                text: 'Overview',
              ),
              Tab(
                key: _tutorialTabKey,
                icon: Stack(
                  children: [
                    const Icon(Icons.play_circle_filled),
                    if (_tutorialCompleted)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
                text: 'Tutorials',
              ),
              Tab(
                key: _practiceTabKey,
                icon: Stack(
                  children: [
                    const Icon(Icons.psychology),
                    if (_practiceCompleted)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
                text: 'Practice',
              ),
            ],
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(theme, isDark),
            _buildTutorialTab(theme, isDark),
            _buildPracticeTab(theme, isDark),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(theme),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _transitionController.value)),
          child: Opacity(
            opacity: _transitionController.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(theme, isDark),
                  const SizedBox(height: 24),
                  _buildFeatureGrid(theme, isDark),
                  const SizedBox(height: 24),
                  _buildProgressCard(theme, isDark),
                  const SizedBox(height: 24),
                  _buildQuickStartCard(theme, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
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
                      const Color(0xFF4B7BEC),
                      const Color(0xFF6C5CE7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Crypto Learning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Master Shamir\'s Secret Sharing through hands-on experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'This comprehensive learning system combines visual tutorials, interactive animations, and practical exercises to help you understand and master the concepts of cryptographic secret sharing.',
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All learning uses safe sample data - your real secrets remain secure',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(ThemeData theme, bool isDark) {
    final features = [
      FeatureCard(
        title: 'Visual Tutorials',
        description: 'Interactive animations showing cryptographic concepts',
        icon: Icons.play_circle_filled,
        color: const Color(0xFF4B7BEC),
        isCompleted: _tutorialCompleted,
      ),
      FeatureCard(
        title: 'Practice Mode',
        description: 'Hands-on exercises with real-time feedback',
        icon: Icons.psychology,
        color: const Color(0xFF00D395),
        isCompleted: _practiceCompleted,
      ),
      FeatureCard(
        title: 'Wireframe Guide',
        description: 'Interactive overlay system for guidance',
        icon: Icons.visibility,
        color: const Color(0xFF6C5CE7),
        isCompleted: false,
      ),
      FeatureCard(
        title: 'Progress Tracking',
        description: 'Monitor your learning journey',
        icon: Icons.analytics,
        color: const Color(0xFFFF6B6B),
        isCompleted: _tutorialCompleted && _practiceCompleted,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature, theme, isDark);
      },
    );
  }

  Widget _buildFeatureCard(FeatureCard feature, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: PremiumTheme.getPremiumCard(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      feature.color,
                      feature.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (feature.isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            feature.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, bool isDark) {
    final completionPercentage = _calculateCompletionPercentage();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.getPremiumCard(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${completionPercentage.toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildProgressItem('Tutorials', _tutorialCompleted),
              const SizedBox(width: 16),
              _buildProgressItem('Practice', _practiceCompleted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, bool completed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: completed ? Colors.green : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStartCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4B7BEC).withValues(alpha: 0.1),
            const Color(0xFF6C5CE7).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B7BEC).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Start Learning?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Begin with tutorials to understand the concepts, then practice with hands-on exercises.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Tutorials'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(2),
                  icon: const Icon(Icons.psychology),
                  label: const Text('Try Practice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B7BEC),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CryptoTutorialAnimations(
            type: CryptoTutorialType.secretSplitting,
            onComplete: _onTutorialComplete,
          ),
          const SizedBox(height: 24),
          CryptoTutorialAnimations(
            type: CryptoTutorialType.secretReconstruction,
            autoPlay: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PracticeModeSystem(
        scenario: PracticeScenario.fullWorkflow,
        onComplete: _onPracticeComplete,
        difficulty: Difficulty.beginner,
      ),
    );
  }

  Widget? _buildFloatingActionButton(ThemeData theme) {
    if (_tutorialCompleted && _practiceCompleted) {
      return FloatingActionButton.extended(
        onPressed: _navigateToMainApp,
        icon: const Icon(Icons.rocket_launch),
        label: const Text('Start Using App'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      );
    }
    return null;
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsBottomSheet(),
    );
  }

  Widget _buildSettingsBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.getPremiumCard(
        isDark: isDark,
        isElevated: true,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 20),
          
          SwitchListTile(
            title: const Text('Show Hints'),
            subtitle: const Text('Display helpful hints during practice'),
            value: true,
            onChanged: (value) {},
          ),
          
          SwitchListTile(
            title: const Text('Auto-advance'),
            subtitle: const Text('Automatically move to next step when completed'),
            value: true,
            onChanged: (value) {},
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Progress'),
            subtitle: const Text('Clear all completion status'),
            onTap: () {
              setState(() {
                _tutorialCompleted = false;
                _practiceCompleted = false;
              });
              Navigator.of(context).pop();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Show Guide'),
            subtitle: const Text('Enable wireframe overlay system'),
            onTap: () {
              Navigator.of(context).pop();
              _toggleWireframeMode();
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  double _calculateCompletionPercentage() {
    int completed = 0;
    if (_tutorialCompleted) completed++;
    if (_practiceCompleted) completed++;
    return (completed / 2) * 100;
  }
}

// Data Models
class FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCompleted;

  FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCompleted,
  });
}