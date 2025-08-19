import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Practice Mode System with Visual Feedback
/// Provides hands-on practice with sample secrets and comprehensive feedback
class PracticeModeSystem extends StatefulWidget {
  final PracticeScenario scenario;
  final VoidCallback? onComplete;
  final bool enableHints;
  final Difficulty difficulty;

  const PracticeModeSystem({
    super.key,
    required this.scenario,
    this.onComplete,
    this.enableHints = true,
    this.difficulty = Difficulty.beginner,
  });

  @override
  State<PracticeModeSystem> createState() => _PracticeModeSystemState();
}

class _PracticeModeSystemState extends State<PracticeModeSystem>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late AnimationController _hintController;

  late Animation<double> _feedbackAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Color?> _feedbackColorAnimation;

  PracticeStep _currentStep = PracticeStep.introduction;
  int _currentStepIndex = 0;
  int _score = 0;
  int _maxScore = 100;
  List<FeedbackMessage> _feedbackHistory = [];
  Map<String, dynamic> _userInputs = {};
  bool _isStepComplete = false;
  bool _showHint = false;

  // Sample practice data (never use real secrets)
  final Map<String, SampleSecret> _sampleSecrets = {
    'password': SampleSecret(
      id: 'password',
      name: 'Sample Password',
      content: 'MySecurePassword123!',
      description: 'A strong password for your email account',
      icon: Icons.password,
      color: const Color(0xFF4B7BEC),
    ),
    'recovery': SampleSecret(
      id: 'recovery',
      name: 'Recovery Phrase',
      content: 'abandon ability able about above absent absorb abstract',
      description: 'Sample cryptocurrency recovery phrase',
      icon: Icons.currency_bitcoin,
      color: const Color(0xFF00D395),
    ),
    'pin': SampleSecret(
      id: 'pin',
      name: 'PIN Code',
      content: '1234',
      description: 'Sample 4-digit PIN code',
      icon: Icons.pin,
      color: const Color(0xFF6C5CE7),
    ),
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPracticeSession();
  }

  void _initializeAnimations() {
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _hintController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _feedbackColorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.green,
    ).animate(_feedbackController);
  }

  void _startPracticeSession() {
    _currentStep = PracticeStep.introduction;
    _currentStepIndex = 0;
    _score = 0;
    _addFeedbackMessage(
      'Welcome to Practice Mode! Let\'s learn Shamir\'s Secret Sharing hands-on.',
      FeedbackType.info,
    );
  }

  void _addFeedbackMessage(String message, FeedbackType type, {int? scoreChange}) {
    setState(() {
      _feedbackHistory.add(FeedbackMessage(
        message: message,
        type: type,
        timestamp: DateTime.now(),
        scoreChange: scoreChange,
      ));

      if (scoreChange != null) {
        _score = (_score + scoreChange).clamp(0, _maxScore);
      }
    });

    _feedbackController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _feedbackController.reverse();
      });
    });

    _updateProgressAnimation();
  }

  void _updateProgressAnimation() {
    final targetProgress = _score / _maxScore;
    _progressController.animateTo(targetProgress);
  }

  void _nextStep() {
    if (_currentStepIndex < _getStepsForScenario().length - 1) {
      setState(() {
        _currentStepIndex++;
        _currentStep = _getStepsForScenario()[_currentStepIndex];
        _isStepComplete = false;
        _showHint = false;
      });

      _addFeedbackMessage(
        _getStepInstructions(_currentStep),
        FeedbackType.instruction,
      );
    } else {
      _completePracticeSession();
    }
  }

  void _completePracticeSession() {
    _celebrationController.forward();
    _addFeedbackMessage(
      'Congratulations! You\'ve completed the practice session.',
      FeedbackType.success,
      scoreChange: 20,
    );

    widget.onComplete?.call();
  }

  List<PracticeStep> _getStepsForScenario() {
    switch (widget.scenario) {
      case PracticeScenario.secretSplitting:
        return [
          PracticeStep.introduction,
          PracticeStep.selectSecret,
          PracticeStep.configureThreshold,
          PracticeStep.performSplit,
          PracticeStep.reviewResults,
        ];
      case PracticeScenario.secretReconstruction:
        return [
          PracticeStep.introduction,
          PracticeStep.gatherShares,
          PracticeStep.performReconstruction,
          PracticeStep.verifyResult,
        ];
      case PracticeScenario.fullWorkflow:
        return [
          PracticeStep.introduction,
          PracticeStep.selectSecret,
          PracticeStep.configureThreshold,
          PracticeStep.performSplit,
          PracticeStep.gatherShares,
          PracticeStep.performReconstruction,
          PracticeStep.verifyResult,
        ];
    }
  }

  String _getStepInstructions(PracticeStep step) {
    switch (step) {
      case PracticeStep.introduction:
        return 'Let\'s practice with safe sample data. No real secrets will be used.';
      case PracticeStep.selectSecret:
        return 'Choose a sample secret to practice with.';
      case PracticeStep.configureThreshold:
        return 'Set the threshold (how many shares needed to reconstruct).';
      case PracticeStep.performSplit:
        return 'Split the secret into multiple shares.';
      case PracticeStep.gatherShares:
        return 'Collect the minimum required shares for reconstruction.';
      case PracticeStep.performReconstruction:
        return 'Reconstruct the original secret from the shares.';
      case PracticeStep.verifyResult:
        return 'Verify the reconstructed secret matches the original.';
      case PracticeStep.reviewResults:
        return 'Review the splitting results and understand the shares.';
    }
  }

  void _showHintForCurrentStep() {
    setState(() {
      _showHint = true;
    });

    _hintController.forward();
    _addFeedbackMessage(
      _getHintForStep(_currentStep),
      FeedbackType.hint,
    );
  }

  String _getHintForStep(PracticeStep step) {
    switch (step) {
      case PracticeStep.selectSecret:
        return 'Tip: Start with the PIN code - it\'s the simplest example.';
      case PracticeStep.configureThreshold:
        return 'Try 3 of 5: Split into 5 shares, need any 3 to reconstruct.';
      case PracticeStep.performSplit:
        return 'Click the "Split Secret" button to see the magic happen!';
      case PracticeStep.gatherShares:
        return 'You only need the minimum threshold, not all shares.';
      case PracticeStep.performReconstruction:
        return 'Input the shares exactly as shown - order doesn\'t matter.';
      case PracticeStep.verifyResult:
        return 'The result should match your original secret exactly.';
      default:
        return 'Follow the on-screen instructions step by step.';
    }
  }

  void _validateUserInput(String key, dynamic value) {
    setState(() {
      _userInputs[key] = value;
    });

    // Validate based on current step
    bool isValid = false;
    String feedback = '';
    FeedbackType feedbackType = FeedbackType.error;
    int scoreChange = 0;

    switch (_currentStep) {
      case PracticeStep.selectSecret:
        isValid = _sampleSecrets.containsKey(value);
        if (isValid) {
          feedback = 'Great choice! This ${_sampleSecrets[value]?.name} is perfect for practice.';
          feedbackType = FeedbackType.success;
          scoreChange = 10;
        } else {
          feedback = 'Please select a valid sample secret.';
        }
        break;

      case PracticeStep.configureThreshold:
        final thresholdData = value as Map<String, int>?;
        if (thresholdData != null) {
          final threshold = thresholdData['threshold'] ?? 0;
          final total = thresholdData['total'] ?? 0;
          
          isValid = threshold >= 2 && threshold <= total && total >= 2 && total <= 10;
          
          if (isValid) {
            feedback = 'Perfect! $threshold of $total is a secure configuration.';
            feedbackType = FeedbackType.success;
            scoreChange = 15;
          } else {
            feedback = 'Check your configuration: threshold must be 2+ and ≤ total shares.';
          }
        }
        break;

      case PracticeStep.performSplit:
        isValid = value == true;
        if (isValid) {
          feedback = 'Excellent! The secret has been split into secure shares.';
          feedbackType = FeedbackType.success;
          scoreChange = 20;
        }
        break;

      case PracticeStep.performReconstruction:
        isValid = value == true;
        if (isValid) {
          feedback = 'Perfect reconstruction! The shares were combined correctly.';
          feedbackType = FeedbackType.success;
          scoreChange = 25;
        } else {
          feedback = 'Reconstruction failed. Check your shares and try again.';
        }
        break;

      default:
        isValid = true;
        feedback = 'Step completed successfully.';
        feedbackType = FeedbackType.success;
        scoreChange = 5;
    }

    _addFeedbackMessage(feedback, feedbackType, scoreChange: scoreChange);

    if (isValid) {
      setState(() {
        _isStepComplete = true;
      });

      // Auto-advance after success feedback
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isStepComplete) {
          _nextStep();
        }
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _progressController.dispose();
    _celebrationController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 700,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0A0E1A),
                  const Color(0xFF1C2333),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE8ECF4),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background effects
          _buildBackgroundEffects(),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with progress
                _buildHeader(theme, isDark),
                
                const SizedBox(height: 24),
                
                // Current step content
                Expanded(
                  child: _buildStepContent(theme, isDark),
                ),
                
                const SizedBox(height: 24),
                
                // Feedback panel
                _buildFeedbackPanel(theme, isDark),
                
                const SizedBox(height: 16),
                
                // Action buttons
                _buildActionButtons(theme, isDark),
              ],
            ),
          ),

          // Celebration effects
          if (_celebrationController.isAnimating)
            _buildCelebrationEffects(),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffects() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return CustomPaint(
          painter: PracticeBackgroundPainter(
            progress: _progressAnimation.value,
            scenario: widget.scenario,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4B7BEC),
                      const Color(0xFF6C5CE7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
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
                      'Practice Mode',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getScenarioTitle(widget.scenario),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Score display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.blue.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Text(
                      'Score: $_score/$_maxScore',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStepIndex + 1} of ${_getStepsForScenario().length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
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

  Widget _buildStepContent(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case PracticeStep.introduction:
        return _buildIntroductionStep(theme, isDark);
      case PracticeStep.selectSecret:
        return _buildSecretSelectionStep(theme, isDark);
      case PracticeStep.configureThreshold:
        return _buildThresholdConfigurationStep(theme, isDark);
      case PracticeStep.performSplit:
        return _buildSplitPerformStep(theme, isDark);
      case PracticeStep.gatherShares:
        return _buildGatherSharesStep(theme, isDark);
      case PracticeStep.performReconstruction:
        return _buildReconstructionStep(theme, isDark);
      case PracticeStep.verifyResult:
        return _buildVerificationStep(theme, isDark);
      case PracticeStep.reviewResults:
        return _buildReviewStep(theme, isDark);
    }
  }

  Widget _buildIntroductionStep(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Welcome to Safe Practice!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Practice Shamir\'s Secret Sharing with safe sample data. No real secrets are used - this is purely educational.',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All data used in this practice mode is sample data only. Your real secrets remain secure.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
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

  Widget _buildSecretSelectionStep(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Choose a Sample Secret',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Expanded(
          child: ListView.builder(
            itemCount: _sampleSecrets.length,
            itemBuilder: (context, index) {
              final secret = _sampleSecrets.values.elementAt(index);
              final isSelected = _userInputs['selectedSecret'] == secret.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _validateUserInput('selectedSecret', secret.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  secret.color.withValues(alpha: 0.2),
                                  secret.color.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        color: !isSelected
                            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8))
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? secret.color
                              : theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: secret.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              secret.icon,
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
                                  secret.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  secret.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: secret.color,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Additional step content builders would go here...
  // For brevity, I'll implement key ones

  Widget _buildThresholdConfigurationStep(ThemeData theme, bool isDark) {
    int threshold = _userInputs['threshold'] ?? 3;
    int totalShares = _userInputs['totalShares'] ?? 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Configure Threshold',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Threshold: $threshold',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Slider(
                      value: threshold.toDouble(),
                      min: 2,
                      max: totalShares.toDouble(),
                      divisions: totalShares - 2,
                      onChanged: (value) {
                        setState(() {
                          _userInputs['threshold'] = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Shares: $totalShares',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Slider(
                      value: totalShares.toDouble(),
                      min: math.max(2, threshold).toDouble(),
                      max: 10,
                      divisions: 10 - math.max(2, threshold),
                      onChanged: (value) {
                        setState(() {
                          _userInputs['totalShares'] = value.toInt();
                          if (threshold > value.toInt()) {
                            _userInputs['threshold'] = value.toInt();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'You\'ll need any $threshold shares out of $totalShares to reconstruct the secret.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              _validateUserInput('thresholdConfig', {
                'threshold': threshold,
                'total': totalShares,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Apply Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPanel(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        if (_feedbackHistory.isEmpty) return const SizedBox.shrink();
        
        final latestFeedback = _feedbackHistory.last;
        
        return Transform.scale(
          scale: 0.95 + (_feedbackAnimation.value * 0.05),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: _getFeedbackGradient(latestFeedback.type, isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getFeedbackColor(latestFeedback.type).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFeedbackIcon(latestFeedback.type),
                  color: _getFeedbackColor(latestFeedback.type),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    latestFeedback.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (latestFeedback.scoreChange != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: latestFeedback.scoreChange! > 0 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${latestFeedback.scoreChange! > 0 ? '+' : ''}${latestFeedback.scoreChange}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: latestFeedback.scoreChange! > 0 
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isDark) {
    return Row(
      children: [
        if (widget.enableHints && !_showHint)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showHintForCurrentStep,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Show Hint'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        
        if (widget.enableHints && !_showHint) const SizedBox(width: 16),
        
        if (_isStepComplete)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              icon: Icon(_currentStepIndex < _getStepsForScenario().length - 1
                  ? Icons.arrow_forward
                  : Icons.check),
              label: Text(_currentStepIndex < _getStepsForScenario().length - 1
                  ? 'Next Step'
                  : 'Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCelebrationEffects() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return CustomPaint(
          painter: CelebrationPainter(
            animation: _celebrationController,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // Helper methods for feedback styling
  Color _getFeedbackColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.hint:
        return Colors.purple;
      case FeedbackType.info:
        return Colors.blue;
      case FeedbackType.instruction:
        return Colors.teal;
    }
  }

  IconData _getFeedbackIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Icons.check_circle_outline;
      case FeedbackType.error:
        return Icons.error_outline;
      case FeedbackType.warning:
        return Icons.warning_amber_outlined;
      case FeedbackType.hint:
        return Icons.lightbulb_outline;
      case FeedbackType.info:
        return Icons.info_outline;
      case FeedbackType.instruction:
        return Icons.school_outlined;
    }
  }

  LinearGradient _getFeedbackGradient(FeedbackType type, bool isDark) {
    final color = _getFeedbackColor(type);
    return LinearGradient(
      colors: [
        color.withValues(alpha: isDark ? 0.2 : 0.1),
        color.withValues(alpha: isDark ? 0.1 : 0.05),
      ],
    );
  }

  String _getScenarioTitle(PracticeScenario scenario) {
    switch (scenario) {
      case PracticeScenario.secretSplitting:
        return 'Learn Secret Splitting';
      case PracticeScenario.secretReconstruction:
        return 'Practice Secret Reconstruction';
      case PracticeScenario.fullWorkflow:
        return 'Complete Workflow Practice';
    }
  }

  // Placeholder implementations for missing step builders
  Widget _buildSplitPerformStep(ThemeData theme, bool isDark) => _buildGenericStep('Perform Split', theme);
  Widget _buildGatherSharesStep(ThemeData theme, bool isDark) => _buildGenericStep('Gather Shares', theme);
  Widget _buildReconstructionStep(ThemeData theme, bool isDark) => _buildGenericStep('Reconstruction', theme);
  Widget _buildVerificationStep(ThemeData theme, bool isDark) => _buildGenericStep('Verify Result', theme);
  Widget _buildReviewStep(ThemeData theme, bool isDark) => _buildGenericStep('Review Results', theme);
  
  Widget _buildGenericStep(String title, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _validateUserInput('stepComplete', true),
            child: const Text('Complete Step'),
          ),
        ],
      ),
    );
  }
}

// Enums and Data Models

enum PracticeScenario {
  secretSplitting,
  secretReconstruction,
  fullWorkflow,
}

enum PracticeStep {
  introduction,
  selectSecret,
  configureThreshold,
  performSplit,
  gatherShares,
  performReconstruction,
  verifyResult,
  reviewResults,
}

enum Difficulty {
  beginner,
  intermediate,
  advanced,
}

enum FeedbackType {
  success,
  error,
  warning,
  hint,
  info,
  instruction,
}

class SampleSecret {
  final String id;
  final String name;
  final String content;
  final String description;
  final IconData icon;
  final Color color;

  SampleSecret({
    required this.id,
    required this.name,
    required this.content,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class FeedbackMessage {
  final String message;
  final FeedbackType type;
  final DateTime timestamp;
  final int? scoreChange;

  FeedbackMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    this.scoreChange,
  });
}

// Custom Painters

class PracticeBackgroundPainter extends CustomPainter {
  final double progress;
  final PracticeScenario scenario;

  PracticeBackgroundPainter({
    required this.progress,
    required this.scenario,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw progress-based background effects
    for (int i = 0; i < 15; i++) {
      final x = (i * 60.0) % size.width;
      final y = (size.height * 0.5) + (30 * math.sin((progress * 2 * math.pi) + i));
      final opacity = 0.1 * progress;
      
      paint.color = _getScenarioColor(scenario).withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        4.0,
        paint,
      );
    }
  }

  Color _getScenarioColor(PracticeScenario scenario) {
    switch (scenario) {
      case PracticeScenario.secretSplitting:
        return const Color(0xFF4B7BEC);
      case PracticeScenario.secretReconstruction:
        return const Color(0xFF00D395);
      case PracticeScenario.fullWorkflow:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  bool shouldRepaint(PracticeBackgroundPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class CelebrationPainter extends CustomPainter {
  final Animation<double> animation;

  CelebrationPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw celebration particles
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + i * 0.05) % 1.0;
      final x = (i * 25.0) % size.width;
      final y = size.height - (size.height * progress);
      final opacity = (1.0 - progress) * 0.8;
      
      paint.color = [
        Colors.yellow,
        Colors.orange,
        Colors.pink,
        Colors.purple,
      ][i % 4].withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        3.0 + (progress * 5.0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CelebrationPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}