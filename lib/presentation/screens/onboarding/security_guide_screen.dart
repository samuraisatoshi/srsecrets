import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/premium_theme.dart';

/// Security Best Practices Guide with Interactive Visuals
/// Educational resource for secure storage and handling of secret shares
class SecurityGuideScreen extends StatefulWidget {
  const SecurityGuideScreen({super.key});

  @override
  State<SecurityGuideScreen> createState() => _SecurityGuideScreenState();
}

class _SecurityGuideScreenState extends State<SecurityGuideScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageAnimationController;
  late AnimationController _interactionController;
  late AnimationController _securityMeterController;
  late PageController _pageController;

  int _currentGuideIndex = 0;
  int _selectedStorageOption = -1;
  double _securityScore = 0.0;

  final List<SecurityGuide> _securityGuides = [
    SecurityGuide(
      title: 'Storage Best Practices',
      icon: Icons.storage,
      color: Color(0xFF4B7BEC),
      sections: [
        SecuritySection(
          title: 'Physical Storage Options',
          practices: [
            SecurityPractice(
              title: 'Safety Deposit Box',
              description: 'Bank vault storage with dual-key access control and insurance coverage',
              securityRating: 95,
              pros: ['Highest physical security', 'Insurance protection', 'Fire/flood resistant'],
              cons: ['Limited access hours', 'Annual fees', 'Bank dependency'],
              icon: Icons.account_balance,
              riskLevel: RiskLevel.minimal,
            ),
            SecurityPractice(
              title: 'Home Safe',
              description: 'Fire-resistant safe with digital lock, hidden from plain sight',
              securityRating: 80,
              pros: ['24/7 access', 'No ongoing fees', 'Complete control'],
              cons: ['Vulnerable to extreme disasters', 'Requires maintenance', 'Burglar risk'],
              icon: Icons.safety_check,
              riskLevel: RiskLevel.low,
            ),
            SecurityPractice(
              title: 'Trusted Family/Friends',
              description: 'Sealed envelope with trusted individual who understands importance',
              securityRating: 70,
              pros: ['Human verification', 'Geographic distribution', 'No cost'],
              cons: ['Privacy concerns', 'Relationship dependency', 'Human error risk'],
              icon: Icons.people,
              riskLevel: RiskLevel.moderate,
            ),
            SecurityPractice(
              title: 'Encrypted Cloud Storage',
              description: 'Password-protected, encrypted files in reputable cloud services',
              securityRating: 85,
              pros: ['Global access', 'Automatic backups', 'Service redundancy'],
              cons: ['Internet dependency', 'Third-party risk', 'Account vulnerability'],
              icon: Icons.cloud_done,
              riskLevel: RiskLevel.low,
            ),
          ],
        ),
      ],
    ),
    SecurityGuide(
      title: 'Distribution Strategy',
      icon: Icons.scatter_plot,
      color: Color(0xFF00D395),
      sections: [
        SecuritySection(
          title: 'Geographic Distribution',
          practices: [
            SecurityPractice(
              title: 'Multi-Location Spread',
              description: 'Distribute shares across different cities, states, or countries',
              securityRating: 90,
              pros: ['Disaster resilience', 'Regulatory arbitrage', 'Access flexibility'],
              cons: ['Travel requirements', 'Complex coordination', 'Legal variations'],
              icon: Icons.public,
              riskLevel: RiskLevel.minimal,
            ),
            SecurityPractice(
              title: 'Avoid Single Points of Failure',
              description: 'Never store multiple shares in the same location or with same person',
              securityRating: 100,
              pros: ['Maximum resilience', 'True redundancy', 'Risk isolation'],
              cons: ['Complex management', 'Higher coordination cost'],
              icon: Icons.safety_divider,
              riskLevel: RiskLevel.minimal,
            ),
          ],
        ),
        SecuritySection(
          title: 'Access Control',
          practices: [
            SecurityPractice(
              title: 'Multi-Factor Authentication',
              description: 'Require multiple forms of identity verification for share access',
              securityRating: 95,
              pros: ['Strong authentication', 'Prevents unauthorized access', 'Audit trail'],
              cons: ['Complex setup', 'User training required', 'Recovery challenges'],
              icon: Icons.verified_user,
              riskLevel: RiskLevel.minimal,
            ),
            SecurityPractice(
              title: 'Time-Delayed Access',
              description: 'Implement waiting periods for share retrieval from secure locations',
              securityRating: 85,
              pros: ['Prevents hasty decisions', 'Allows verification', 'Adds security layer'],
              cons: ['Delays legitimate access', 'Emergency complications'],
              icon: Icons.schedule,
              riskLevel: RiskLevel.low,
            ),
          ],
        ),
      ],
    ),
    SecurityGuide(
      title: 'Digital Security',
      icon: Icons.computer,
      color: Color(0xFF6C5CE7),
      sections: [
        SecuritySection(
          title: 'Device Security',
          practices: [
            SecurityPractice(
              title: 'Air-Gapped Generation',
              description: 'Create and split secrets on offline devices never connected to internet',
              securityRating: 100,
              pros: ['Zero network exposure', 'Maximum security', 'No remote attacks'],
              cons: ['Complex setup', 'Limited convenience', 'Requires expertise'],
              icon: Icons.flight_takeoff,
              riskLevel: RiskLevel.minimal,
            ),
            SecurityPractice(
              title: 'Hardware Security Modules',
              description: 'Use dedicated cryptographic hardware for key generation and storage',
              securityRating: 98,
              pros: ['Tamper resistance', 'Certified security', 'Professional grade'],
              cons: ['High cost', 'Complex management', 'Specialist knowledge required'],
              icon: Icons.memory,
              riskLevel: RiskLevel.minimal,
            ),
          ],
        ),
        SecuritySection(
          title: 'Software Security',
          practices: [
            SecurityPractice(
              title: 'Open Source Verification',
              description: 'Use only open-source software that has been independently audited',
              securityRating: 90,
              pros: ['Code transparency', 'Community review', 'No hidden backdoors'],
              cons: ['Technical complexity', 'Update management', 'Support limitations'],
              icon: Icons.code,
              riskLevel: RiskLevel.low,
            ),
            SecurityPractice(
              title: 'Regular Security Updates',
              description: 'Keep all software and operating systems updated with latest security patches',
              securityRating: 85,
              pros: ['Known vulnerability fixes', 'Improved stability', 'Feature updates'],
              cons: ['Potential compatibility issues', 'Regular maintenance required'],
              icon: Icons.system_update,
              riskLevel: RiskLevel.low,
            ),
          ],
        ),
      ],
    ),
    SecurityGuide(
      title: 'Operational Security',
      icon: Icons.security,
      color: Color(0xFFE74C3C),
      sections: [
        SecuritySection(
          title: 'Documentation & Communication',
          practices: [
            SecurityPractice(
              title: 'Secure Documentation',
              description: 'Document processes without exposing sensitive information',
              securityRating: 88,
              pros: ['Process clarity', 'Succession planning', 'Error reduction'],
              cons: ['Documentation security risk', 'Maintenance overhead'],
              icon: Icons.description,
              riskLevel: RiskLevel.low,
            ),
            SecurityPractice(
              title: 'Trusted Communication Channels',
              description: 'Use encrypted messaging and secure channels for coordination',
              securityRating: 92,
              pros: ['Message confidentiality', 'Authentication', 'Non-repudiation'],
              cons: ['Key management complexity', 'User adoption challenges'],
              icon: Icons.message,
              riskLevel: RiskLevel.low,
            ),
          ],
        ),
        SecuritySection(
          title: 'Testing & Recovery',
          practices: [
            SecurityPractice(
              title: 'Regular Recovery Testing',
              description: 'Periodically test your ability to reconstruct secrets using shares',
              securityRating: 95,
              pros: ['Validates process', 'Identifies issues early', 'Builds confidence'],
              cons: ['Exposes shares temporarily', 'Time investment required'],
              icon: Icons.quiz,
              riskLevel: RiskLevel.minimal,
            ),
            SecurityPractice(
              title: 'Emergency Procedures',
              description: 'Define clear procedures for emergency access and share replacement',
              securityRating: 90,
              pros: ['Crisis preparedness', 'Clear responsibilities', 'Reduced stress'],
              cons: ['Complex planning', 'Regular updates needed'],
              icon: Icons.warning,
              riskLevel: RiskLevel.low,
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _securityMeterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pageAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageAnimationController.dispose();
    _interactionController.dispose();
    _securityMeterController.dispose();
    super.dispose();
  }

  void _selectGuide(int index) {
    setState(() {
      _currentGuideIndex = index;
      _selectedStorageOption = -1;
      _securityScore = 0.0;
    });
    
    // Safety check: only animate if PageController has positions attached
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
    _pageAnimationController.reset();
    _pageAnimationController.forward();
  }

  void _selectStorageOption(int practiceIndex) {
    setState(() {
      _selectedStorageOption = practiceIndex;
      if (practiceIndex >= 0 && _securityGuides[_currentGuideIndex].sections.isNotEmpty) {
        final practice = _securityGuides[_currentGuideIndex].sections[0].practices[practiceIndex];
        _securityScore = practice.securityRating / 100.0;
      }
    });
    _interactionController.reset();
    _interactionController.forward();
    _securityMeterController.reset();
    _securityMeterController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;
    final isTablet = size.width > 600;

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
        child: SafeArea(
          child: isDesktop
              ? _buildDesktopLayout(theme, isDark, size)
              : isTablet
                  ? _buildTabletLayout(theme, isDark, size)
                  : _buildMobileLayout(theme, isDark, size),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, bool isDark, Size size) {
    return Row(
      children: [
        // Left sidebar - Guide navigation
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 32),
              Expanded(child: _buildGuideNavigation(theme, isDark)),
              _buildSecurityMeter(theme, isDark),
            ],
          ),
        ),
        
        // Main content area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: _buildMainContent(theme, isDark, size),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme, bool isDark, Size size) {
    return Column(
      children: [
        // Header and navigation
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 24),
              SizedBox(
                height: 80,
                child: _buildHorizontalGuideNavigation(theme, isDark),
              ),
            ],
          ),
        ),
        
        // Main content
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildMainContent(theme, isDark, size),
          ),
        ),
        
        // Bottom security meter
        Container(
          padding: const EdgeInsets.all(24),
          child: _buildSecurityMeter(theme, isDark),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme, bool isDark, Size size) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          child: _buildHeader(theme, isDark),
        ),
        
        // Guide tabs
        SizedBox(
          height: 60,
          child: _buildMobileGuideTabs(theme, isDark),
        ),
        
        // Content
        Expanded(
          child: _buildMainContent(theme, isDark, size),
        ),
        
        // Security meter
        if (_selectedStorageOption >= 0)
          Container(
            padding: const EdgeInsets.all(20),
            child: _buildSecurityMeter(theme, isDark),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _pageAnimationController.value)),
          child: Opacity(
            opacity: _pageAnimationController.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4B7BEC),
                            Color(0xFF6C5CE7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.security,
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
                            'Security Best Practices',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Professional-grade security guidance',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideNavigation(ThemeData theme, bool isDark) {
    return Column(
      children: _securityGuides.asMap().entries.map((entry) {
        final index = entry.key;
        final guide = entry.value;
        final isSelected = index == _currentGuideIndex;

        return _buildGuideNavigationItem(
          guide,
          isSelected,
          () => _selectGuide(index),
          theme,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalGuideNavigation(ThemeData theme, bool isDark) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _securityGuides.length,
      itemBuilder: (context, index) {
        final guide = _securityGuides[index];
        final isSelected = index == _currentGuideIndex;

        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 16),
          child: _buildGuideNavigationItem(
            guide,
            isSelected,
            () => _selectGuide(index),
            theme,
            isDark,
            isHorizontal: true,
          ),
        );
      },
    );
  }

  Widget _buildMobileGuideTabs(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _securityGuides.asMap().entries.map((entry) {
            final index = entry.key;
            final guide = entry.value;
            final isSelected = index == _currentGuideIndex;

            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectGuide(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                guide.color,
                                guide.color.withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: !isSelected
                          ? theme.colorScheme.surfaceContainer
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          guide.icon,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          guide.title.split(' ').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGuideNavigationItem(
    SecurityGuide guide,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark, {
    bool isHorizontal = false,
  }) {
    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            isHorizontal ? 0 : -20 * (1 - _pageAnimationController.value),
            isHorizontal ? 20 * (1 - _pageAnimationController.value) : 0,
          ),
          child: Opacity(
            opacity: _pageAnimationController.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                guide.color.withValues(alpha: 0.2),
                                guide.color.withValues(alpha: 0.1),
                              ],
                            )
                          : null,
                      color: !isSelected
                          ? theme.colorScheme.surfaceContainer
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: guide.color.withValues(alpha: 0.3),
                              width: 2,
                            )
                          : Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                guide.color,
                                guide.color.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            guide.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (!isHorizontal) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              guide.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? guide.color
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark, Size size) {
    final selectedGuide = _securityGuides[_currentGuideIndex];

    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - _pageAnimationController.value), 0),
          child: Opacity(
            opacity: _pageAnimationController.value,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guide header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: PremiumTheme.getPremiumCard(
                      isDark: isDark,
                      isElevated: true,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                selectedGuide.color,
                                selectedGuide.color.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            selectedGuide.icon,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedGuide.title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Professional security recommendations',
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
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sections
                  ...selectedGuide.sections.map((section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(section, selectedGuide, theme, isDark),
                      const SizedBox(height: 16),
                      _buildPracticesGrid(section, selectedGuide, theme, isDark, size),
                      const SizedBox(height: 32),
                    ],
                  )),
                  
                  // Selected practice details
                  if (_selectedStorageOption >= 0 && selectedGuide.sections.isNotEmpty)
                    _buildPracticeDetails(
                      selectedGuide.sections[0].practices[_selectedStorageOption],
                      selectedGuide,
                      theme,
                      isDark,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    SecuritySection section,
    SecurityGuide guide,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            guide.color.withValues(alpha: 0.1),
            guide.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: guide.color.withValues(alpha: 0.3),
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
                  guide.color,
                  guide.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            section.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticesGrid(
    SecuritySection section,
    SecurityGuide guide,
    ThemeData theme,
    bool isDark,
    Size size,
  ) {
    final crossAxisCount = size.width > 1200 ? 2 : 1;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: section.practices.length,
      itemBuilder: (context, index) {
        final practice = section.practices[index];
        final isSelected = _selectedStorageOption == index;
        
        return _buildPracticeCard(
          practice,
          isSelected,
          () => _selectStorageOption(index),
          guide,
          theme,
          isDark,
        );
      },
    );
  }

  Widget _buildPracticeCard(
    SecurityPractice practice,
    bool isSelected,
    VoidCallback onTap,
    SecurityGuide guide,
    ThemeData theme,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      guide.color.withValues(alpha: 0.15),
                      guide.color.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: !isSelected ? theme.colorScheme.surfaceContainer : null,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: guide.color,
                    width: 2,
                  )
                : Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          practice.riskLevel.color,
                          practice.riskLevel.color.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      practice.icon,
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
                          practice.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? guide.color
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildSecurityRating(practice.securityRating, practice.riskLevel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                practice.description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityRating(int rating, RiskLevel riskLevel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                riskLevel.color,
                riskLevel.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$rating%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: riskLevel.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: riskLevel.color.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            riskLevel.label,
            style: TextStyle(
              color: riskLevel.color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeDetails(
    SecurityPractice practice,
    SecurityGuide guide,
    ThemeData theme,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _interactionController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * _interactionController.value),
          child: Opacity(
            opacity: _interactionController.value,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
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
                              practice.riskLevel.color,
                              practice.riskLevel.color.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          practice.icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              practice.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildSecurityRating(practice.securityRating, practice.riskLevel),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    practice.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildProsConsCard(
                          'Advantages',
                          practice.pros,
                          Icons.thumb_up,
                          Colors.green,
                          theme,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProsConsCard(
                          'Considerations',
                          practice.cons,
                          Icons.warning_amber,
                          Colors.orange,
                          theme,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProsConsCard(
    String title,
    List<String> items,
    IconData icon,
    Color accentColor,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildSecurityMeter(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _securityMeterController,
      builder: (context, child) {
        final animatedScore = _securityScore * _securityMeterController.value;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: PremiumTheme.getPremiumCard(isDark: isDark),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4B7BEC), Color(0xFF6C5CE7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.speed,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Security Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Security meter
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: MediaQuery.of(context).size.width * 0.25 * animatedScore,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getSecurityGradient(animatedScore),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(animatedScore * 100).toInt()}% Secure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getSecurityColor(animatedScore),
                    ),
                  ),
                  Text(
                    _getSecurityLabel(animatedScore),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _getSecurityGradient(double score) {
    if (score < 0.6) {
      return [Colors.red, Colors.orange];
    } else if (score < 0.8) {
      return [Colors.orange, Colors.yellow];
    } else {
      return [Colors.green, Color(0xFF00BF63)];
    }
  }

  Color _getSecurityColor(double score) {
    if (score < 0.6) {
      return Colors.red;
    } else if (score < 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getSecurityLabel(double score) {
    if (score < 0.6) {
      return 'Needs Improvement';
    } else if (score < 0.8) {
      return 'Good Security';
    } else {
      return 'Excellent Security';
    }
  }
}

// Data Models
class SecurityGuide {
  final String title;
  final IconData icon;
  final Color color;
  final List<SecuritySection> sections;

  SecurityGuide({
    required this.title,
    required this.icon,
    required this.color,
    required this.sections,
  });
}

class SecuritySection {
  final String title;
  final List<SecurityPractice> practices;

  SecuritySection({
    required this.title,
    required this.practices,
  });
}

class SecurityPractice {
  final String title;
  final String description;
  final int securityRating;
  final List<String> pros;
  final List<String> cons;
  final IconData icon;
  final RiskLevel riskLevel;

  SecurityPractice({
    required this.title,
    required this.description,
    required this.securityRating,
    required this.pros,
    required this.cons,
    required this.icon,
    required this.riskLevel,
  });
}

enum RiskLevel {
  minimal(Color(0xFF00BF63), 'Minimal Risk'),
  low(Color(0xFF4B7BEC), 'Low Risk'),
  moderate(Color(0xFFFFAA00), 'Moderate Risk'),
  high(Color(0xFFFF6B6B), 'High Risk');

  const RiskLevel(this.color, this.label);
  final Color color;
  final String label;
}