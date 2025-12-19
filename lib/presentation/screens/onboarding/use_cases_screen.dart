import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/premium_theme.dart';

/// Business & Personal Use Case Visuals with Interactive Elements
/// Showcases real-world scenarios where Shamir's Secret Sharing provides value
class UseCasesScreen extends StatefulWidget {
  const UseCasesScreen({super.key});

  @override
  State<UseCasesScreen> createState() => _UseCasesScreenState();
}

class _UseCasesScreenState extends State<UseCasesScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _cardController;
  late AnimationController _interactionController;
  
  int _selectedCaseIndex = 0;
  int _selectedScenario = 0;
  
  final List<UseCaseCategory> _categories = [
    UseCaseCategory(
      title: 'Personal Security',
      icon: Icons.person_pin_circle,
      color: Color(0xFF4B7BEC),
      scenarios: [
        UseCaseScenario(
          title: 'Cryptocurrency Recovery',
          problem: 'Lost wallet seed phrase = lost crypto forever',
          solution: 'Split seed phrase into 5 shares, need any 3 to recover',
          stakeholders: ['You', 'Family Member', 'Bank Safe', 'Home Safe', 'Cloud Storage'],
          benefits: [
            'Never lose access to your crypto',
            'Survive theft, fire, or memory loss',
            'Family can help recover if needed',
          ],
          riskReduction: '95%',
          icon: Icons.currency_bitcoin,
          visualType: VisualType.seedPhrase,
        ),
        UseCaseScenario(
          title: 'Password Manager Master Key',
          problem: 'Forgotten master password locks out all accounts',
          solution: 'Backup master password across multiple secure locations',
          stakeholders: ['Personal Device', 'Spouse', 'Parent', 'Safety Deposit', 'Secure Note'],
          benefits: [
            'Access all accounts even if you forget',
            'Trusted family can assist in emergency',
            'No single point of failure',
          ],
          riskReduction: '90%',
          icon: Icons.password,
          visualType: VisualType.password,
        ),
        UseCaseScenario(
          title: 'Digital Estate Planning',
          problem: 'Family cannot access your digital accounts when needed',
          solution: 'Share account recovery information securely with heirs',
          stakeholders: ['Spouse', 'Attorney', 'Trustee', 'Executor', 'Safe Storage'],
          benefits: [
            'Smooth digital asset transfer',
            'Protected from unauthorized access',
            'Legal compliance maintained',
          ],
          riskReduction: '85%',
          icon: Icons.account_balance,
          visualType: VisualType.estate,
        ),
      ],
    ),
    UseCaseCategory(
      title: 'Business Operations',
      icon: Icons.business,
      color: Color(0xFF00D395),
      scenarios: [
        UseCaseScenario(
          title: 'Root SSL Certificate',
          problem: 'Single admin with SSL keys creates business risk',
          solution: 'Distribute certificate authority keys across executives',
          stakeholders: ['CTO', 'CEO', 'Security Lead', 'Backup Admin', 'HSM Device'],
          benefits: [
            'No single person can compromise security',
            'Survive key personnel changes',
            'Meet compliance requirements',
          ],
          riskReduction: '98%',
          icon: Icons.security,
          visualType: VisualType.certificate,
        ),
        UseCaseScenario(
          title: 'Database Encryption Keys',
          problem: 'Database admin departure could lock critical systems',
          solution: 'Split database master keys among senior staff',
          stakeholders: ['Lead DBA', 'CTO', 'DevOps Lead', 'Security Officer', 'Emergency Admin'],
          benefits: [
            'Business continuity guaranteed',
            'Regulatory compliance maintained',
            'Zero trust architecture enabled',
          ],
          riskReduction: '92%',
          icon: Icons.storage,
          visualType: VisualType.database,
        ),
        UseCaseScenario(
          title: 'API Master Keys',
          problem: 'Critical API access tied to single developer account',
          solution: 'Distribute production API keys across team leads',
          stakeholders: ['Tech Lead', 'Product Manager', 'DevOps Engineer', 'QA Lead', 'Backup Developer'],
          benefits: [
            'Prevent production outages',
            'Enable secure key rotation',
            'Distribute operational responsibility',
          ],
          riskReduction: '88%',
          icon: Icons.key,
          visualType: VisualType.apiKeys,
        ),
      ],
    ),
    UseCaseCategory(
      title: 'Enterprise Compliance',
      icon: Icons.verified_user,
      color: Color(0xFF6C5CE7),
      scenarios: [
        UseCaseScenario(
          title: 'GDPR Encryption Keys',
          problem: 'Data protection officer leaves with only copy of encryption keys',
          solution: 'Distribute GDPR compliance keys across legal and tech teams',
          stakeholders: ['Legal Counsel', 'DPO', 'CISO', 'Compliance Officer', 'External Auditor'],
          benefits: [
            'Maintain GDPR compliance',
            'Enable data subject rights',
            'Survive personnel changes',
          ],
          riskReduction: '99%',
          icon: Icons.policy,
          visualType: VisualType.compliance,
        ),
        UseCaseScenario(
          title: 'SOC 2 Audit Keys',
          problem: 'Security controls fail audit due to single key holder',
          solution: 'Implement shared responsibility for audit evidence',
          stakeholders: ['CISO', 'Internal Auditor', 'External Auditor', 'Compliance Team', 'Board Member'],
          benefits: [
            'Pass security audits consistently',
            'Demonstrate proper controls',
            'Reduce audit findings risk',
          ],
          riskReduction: '94%',
          icon: Icons.assessment,
          visualType: VisualType.audit,
        ),
        UseCaseScenario(
          title: 'Financial Controls',
          problem: 'Single CFO access to financial systems creates risk',
          solution: 'Split financial system access among senior executives',
          stakeholders: ['CFO', 'Controller', 'Treasurer', 'CEO', 'Board Audit Committee'],
          benefits: [
            'Prevent financial fraud',
            'Enable proper segregation of duties',
            'Satisfy auditor requirements',
          ],
          riskReduction: '96%',
          icon: Icons.account_balance_wallet,
          visualType: VisualType.financial,
        ),
      ],
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCaseIndex = index;
      _selectedScenario = 0;
    });
    _cardController.reset();
    _cardController.forward();
  }

  void _selectScenario(int index) {
    setState(() {
      _selectedScenario = index;
    });
    _interactionController.reset();
    _interactionController.forward();
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
        // Left sidebar - Categories
        Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 32),
              _buildCategorySelector(theme, isDark),
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
        // Top section - Header and categories
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 24),
              SizedBox(
                height: 100,
                child: _buildHorizontalCategorySelector(theme, isDark),
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
        
        // Category tabs - increased height for better touch targets
        SizedBox(
          height: 68,
          child: _buildMobileCategoryTabs(theme, isDark),
        ),
        
        // Content
        Expanded(
          child: _buildMainContent(theme, isDark, size),
        ),
      ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-World Use Cases',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _categories[_selectedCaseIndex].color,
                      _categories[_selectedCaseIndex].color.withValues(alpha: 0.8),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Discover how professionals protect critical secrets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(ThemeData theme, bool isDark) {
    return Column(
      children: _categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final isSelected = index == _selectedCaseIndex;

        return _buildCategoryCard(
          category,
          isSelected,
          () => _selectCategory(index),
          theme,
          isDark,
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalCategorySelector(ThemeData theme, bool isDark) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = index == _selectedCaseIndex;

        return Container(
          width: 200,
          margin: const EdgeInsets.only(right: 16),
          child: _buildCategoryCard(
            category,
            isSelected,
            () => _selectCategory(index),
            theme,
            isDark,
            isHorizontal: true,
          ),
        );
      },
    );
  }

  Widget _buildMobileCategoryTabs(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = index == _selectedCaseIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectCategory(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            category.color,
                            category.color.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color: !isSelected
                      ? theme.colorScheme.surfaceContainer
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: !isSelected
                      ? Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.title.split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(
    UseCaseCategory category,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark, {
    bool isHorizontal = false,
  }) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            isHorizontal ? 0 : -20 * (1 - _slideController.value),
            isHorizontal ? 20 * (1 - _slideController.value) : 0,
          ),
          child: Opacity(
            opacity: _slideController.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Material(
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
                                category.color.withValues(alpha: 0.2),
                                category.color.withValues(alpha: 0.1),
                              ],
                            )
                          : null,
                      color: !isSelected
                          ? theme.colorScheme.surfaceContainer
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: category.color.withValues(alpha: 0.3),
                              width: 2,
                            )
                          : Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                category.color,
                                category.color.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (!isHorizontal) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? category.color
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${category.scenarios.length} scenarios',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(ThemeData theme, bool isDark, Size size) {
    final selectedCategory = _categories[_selectedCaseIndex];
    final selectedScenario = selectedCategory.scenarios[_selectedScenario];

    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - _cardController.value), 0),
          child: Opacity(
            opacity: _cardController.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scenario selector
                _buildScenarioSelector(selectedCategory, theme, isDark),
                
                const SizedBox(height: 32),
                
                // Selected scenario details
                Expanded(
                  child: _buildScenarioDetails(selectedScenario, theme, isDark, size),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenarioSelector(UseCaseCategory category, ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: category.scenarios.asMap().entries.map((entry) {
          final index = entry.key;
          final scenario = entry.value;
          final isSelected = index == _selectedScenario;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectScenario(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              category.color,
                              category.color.withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: !isSelected
                        ? theme.colorScheme.surfaceContainer
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: !isSelected
                        ? Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scenario.icon,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scenario.title,
                        style: TextStyle(
                          fontSize: 14,
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
    );
  }

  Widget _buildScenarioDetails(
    UseCaseScenario scenario,
    ThemeData theme,
    bool isDark,
    Size size,
  ) {
    final category = _categories[_selectedCaseIndex];
    
    return SingleChildScrollView(
      child: AnimatedBuilder(
        animation: _interactionController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _interactionController.value)),
            child: Opacity(
              opacity: _interactionController.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero section with visualization
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: PremiumTheme.getPremiumCard(
                      isDark: isDark,
                      isElevated: true,
                    ),
                    child: Column(
                      children: [
                        // Title and description
                        Text(
                          scenario.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Interactive visualization
                        _buildInteractiveVisualization(scenario, category, theme, isDark),
                        
                        const SizedBox(height: 32),
                        
                        // Risk reduction metric
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withValues(alpha: 0.1),
                                Colors.green.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green, Color(0xFF00BF63)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Risk Reduction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    scenario.riskReduction,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Problem vs Solution comparison
                  Row(
                    children: [
                      Expanded(
                        child: _buildProblemSolutionCard(
                          'The Problem',
                          scenario.problem,
                          Icons.warning_amber,
                          Colors.orange,
                          theme,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildProblemSolutionCard(
                          'Our Solution',
                          scenario.solution,
                          Icons.lightbulb,
                          category.color,
                          theme,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stakeholder visualization
                  _buildStakeholderSection(scenario, category, theme, isDark),
                  
                  const SizedBox(height: 24),
                  
                  // Benefits list
                  _buildBenefitsSection(scenario, category, theme, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractiveVisualization(
    UseCaseScenario scenario,
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    switch (scenario.visualType) {
      case VisualType.seedPhrase:
        return _buildSeedPhraseVisualization(category, theme, isDark);
      case VisualType.certificate:
        return _buildCertificateVisualization(category, theme, isDark);
      case VisualType.database:
        return _buildDatabaseVisualization(category, theme, isDark);
      default:
        return _buildGenericVisualization(category, theme, isDark);
    }
  }

  Widget _buildSeedPhraseVisualization(
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center - Original seed phrase
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color,
                  category.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  '12-word\nSeed Phrase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Distributed shares around the center
          ...List.generate(5, (index) {
            final angle = (index * 72) * (math.pi / 180);
            final radius = 100.0;
            final x = radius * math.cos(angle);
            final y = radius * math.sin(angle);
            
            return Transform.translate(
              offset: Offset(x, y),
              child: _buildShareVisualization(
                index + 1,
                _getShareLocation(index),
                category.color,
                theme,
              ),
            );
          }),
          
          // Connection lines
          CustomPaint(
            size: const Size(220, 220),
            painter: ConnectionLinesPainter(
              centerColor: category.color,
              shareColor: category.color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateVisualization(
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 200,
      child: Column(
        children: [
          // SSL Certificate representation
          Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color,
                  category.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'SSL Certificate\nPrivate Key',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Arrow pointing down
          Icon(
            Icons.keyboard_arrow_down,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          
          const SizedBox(height: 16),
          
          // Executive shares
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExecutiveShare('CTO', Icons.code, category.color),
              _buildExecutiveShare('CEO', Icons.business, category.color),
              _buildExecutiveShare('CISO', Icons.shield, category.color),
              _buildExecutiveShare('Admin', Icons.admin_panel_settings, category.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseVisualization(
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Database
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  category.color,
                  category.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storage,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          // Flow arrows and key shares
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _buildKeyShare('Key 1', category.color.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  _buildKeyShare('Key 2', category.color.withValues(alpha: 0.8)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  _buildKeyShare('Key 3', category.color.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  _buildKeyShare('Key 4', category.color.withValues(alpha: 0.8)),
                ],
              ),
            ],
          ),
          
          // Team members
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamMember('DBA', Icons.person),
              _buildTeamMember('DevOps', Icons.settings),
              _buildTeamMember('Security', Icons.security),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericVisualization(
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 200,
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                category.color.withValues(alpha: 0.2),
                category.color.withValues(alpha: 0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            category.icon,
            size: 60,
            color: category.color,
          ),
        ),
      ),
    );
  }

  Widget _buildShareVisualization(
    int shareNumber,
    String location,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.6),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$shareNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            location,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveShare(String role, IconData icon, Color color) {
    return Container(
      width: 60,
      height: 80,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyShare(String label, Color color) {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMember(String role, IconData icon) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getShareLocation(int index) {
    switch (index) {
      case 0: return 'Home';
      case 1: return 'Bank';
      case 2: return 'Cloud';
      case 3: return 'Family';
      case 4: return 'Work';
      default: return 'Safe';
    }
  }

  Widget _buildProblemSolutionCard(
    String title,
    String content,
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
        borderRadius: BorderRadius.circular(16),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholderSection(
    UseCaseScenario scenario,
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
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
                    colors: [
                      category.color,
                      category.color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Key Stakeholders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: scenario.stakeholders.map((stakeholder) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      category.color.withValues(alpha: 0.1),
                      category.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  stakeholder,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(
    UseCaseScenario scenario,
    UseCaseCategory category,
    ThemeData theme,
    bool isDark,
  ) {
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
                    colors: [
                      Colors.green,
                      Colors.green.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Key Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...scenario.benefits.map((benefit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Color(0xFF00BF63)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Data Models
class UseCaseCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<UseCaseScenario> scenarios;

  UseCaseCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.scenarios,
  });
}

class UseCaseScenario {
  final String title;
  final String problem;
  final String solution;
  final List<String> stakeholders;
  final List<String> benefits;
  final String riskReduction;
  final IconData icon;
  final VisualType visualType;

  UseCaseScenario({
    required this.title,
    required this.problem,
    required this.solution,
    required this.stakeholders,
    required this.benefits,
    required this.riskReduction,
    required this.icon,
    required this.visualType,
  });
}

enum VisualType {
  seedPhrase,
  password,
  estate,
  certificate,
  database,
  apiKeys,
  compliance,
  audit,
  financial,
}

// Custom Painter for connection lines
class ConnectionLinesPainter extends CustomPainter {
  final Color centerColor;
  final Color shareColor;

  ConnectionLinesPainter({
    required this.centerColor,
    required this.shareColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 100.0;

    // Draw lines from center to each share
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * (math.pi / 180);
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      final sharePosition = Offset(center.dx + x, center.dy + y);

      paint.color = shareColor.withValues(alpha: 0.3);
      canvas.drawLine(center, sharePosition, paint);
    }
  }

  @override
  bool shouldRepaint(ConnectionLinesPainter oldDelegate) {
    return centerColor != oldDelegate.centerColor ||
           shareColor != oldDelegate.shareColor;
  }
}