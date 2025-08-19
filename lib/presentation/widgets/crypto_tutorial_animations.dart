import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Crypto Tutorial Animations
/// Provides animated tutorials with particle effects and drag-drop functionality
class CryptoTutorialAnimations extends StatefulWidget {
  final CryptoTutorialType type;
  final VoidCallback? onComplete;
  final bool autoPlay;
  final Duration animationDuration;

  const CryptoTutorialAnimations({
    super.key,
    required this.type,
    this.onComplete,
    this.autoPlay = true,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<CryptoTutorialAnimations> createState() => _CryptoTutorialAnimationsState();
}

class _CryptoTutorialAnimationsState extends State<CryptoTutorialAnimations>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _dragController;
  late AnimationController _pulseController;

  late Animation<double> _splitAnimation;
  late Animation<double> _reconstructAnimation;
  late Animation<double> _fadeAnimation;

  List<DraggableShare> _draggableShares = [];
  List<ShareSlot> _shareSlots = [];
  int _completedShares = 0;
  bool _isInteractionEnabled = true;
  TutorialPhase _currentPhase = TutorialPhase.introduction;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTutorialData();
    
    if (widget.autoPlay) {
      _startTutorial();
    }
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _dragController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _splitAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _reconstructAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInCubic),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeTutorialData() {
    switch (widget.type) {
      case CryptoTutorialType.secretSplitting:
        _initializeSecretSplitting();
        break;
      case CryptoTutorialType.secretReconstruction:
        _initializeSecretReconstruction();
        break;
      case CryptoTutorialType.thresholdConcept:
        _initializeThresholdConcept();
        break;
      case CryptoTutorialType.shareDistribution:
        _initializeShareDistribution();
        break;
    }
  }

  void _initializeSecretSplitting() {
    // Create draggable shares for splitting tutorial
    _draggableShares = [
      DraggableShare(
        id: 'share_1',
        content: 'Share 1/5',
        color: const Color(0xFF4B7BEC),
        position: const Offset(50, 200),
      ),
      DraggableShare(
        id: 'share_2',
        content: 'Share 2/5',
        color: const Color(0xFF00D395),
        position: const Offset(150, 200),
      ),
      DraggableShare(
        id: 'share_3',
        content: 'Share 3/5',
        color: const Color(0xFF6C5CE7),
        position: const Offset(250, 200),
      ),
    ];
  }

  void _initializeSecretReconstruction() {
    // Create slots for reconstruction tutorial
    _shareSlots = [
      ShareSlot(
        id: 'slot_1',
        position: const Offset(50, 400),
        requiredShareId: 'share_1',
        isRequired: true,
      ),
      ShareSlot(
        id: 'slot_2',
        position: const Offset(150, 400),
        requiredShareId: 'share_2',
        isRequired: true,
      ),
      ShareSlot(
        id: 'slot_3',
        position: const Offset(250, 400),
        requiredShareId: 'share_3',
        isRequired: true,
      ),
    ];

    _draggableShares = [
      DraggableShare(
        id: 'share_1',
        content: 'Share 1/5',
        color: const Color(0xFF4B7BEC),
        position: const Offset(50, 100),
      ),
      DraggableShare(
        id: 'share_2',
        content: 'Share 2/5',
        color: const Color(0xFF00D395),
        position: const Offset(150, 100),
      ),
      DraggableShare(
        id: 'share_3',
        content: 'Share 3/5',
        color: const Color(0xFF6C5CE7),
        position: const Offset(250, 100),
      ),
      DraggableShare(
        id: 'share_4',
        content: 'Share 4/5',
        color: const Color(0xFFFF6B6B),
        position: const Offset(350, 100),
      ),
      DraggableShare(
        id: 'share_5',
        content: 'Share 5/5',
        color: const Color(0xFFFFB800),
        position: const Offset(450, 100),
      ),
    ];
  }

  void _initializeThresholdConcept() {
    // Initialize threshold demonstration
    _currentPhase = TutorialPhase.introduction;
  }

  void _initializeShareDistribution() {
    // Initialize distribution tutorial
    _currentPhase = TutorialPhase.introduction;
  }

  void _startTutorial() {
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _mainController.forward();
    
    if (widget.type == CryptoTutorialType.secretReconstruction) {
      _currentPhase = TutorialPhase.interaction;
      _isInteractionEnabled = true;
    }
  }

  void _onShareDragEnd(DraggableShare share, Offset globalPosition) {
    final localPosition = _globalToLocal(globalPosition);
    
    // Check if share is dropped on a valid slot
    for (final slot in _shareSlots) {
      if (_isPositionInSlot(localPosition, slot)) {
        if (slot.requiredShareId == null || slot.requiredShareId == share.id) {
          _placeShareInSlot(share, slot);
          return;
        }
      }
    }
    
    // Return share to original position if not placed
    _returnShareToOriginalPosition(share);
  }

  Offset _globalToLocal(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  bool _isPositionInSlot(Offset position, ShareSlot slot) {
    const slotRadius = 40.0;
    final distance = (position - slot.position).distance;
    return distance <= slotRadius;
  }

  void _placeShareInSlot(DraggableShare share, ShareSlot slot) {
    setState(() {
      share.position = slot.position;
      slot.occupiedBy = share.id;
      _completedShares++;
    });

    HapticFeedback.mediumImpact();
    _dragController.forward().then((_) => _dragController.reverse());

    if (_completedShares >= _shareSlots.where((s) => s.isRequired).length) {
      _completeInteraction();
    }
  }

  void _returnShareToOriginalPosition(DraggableShare share) {
    // Animate back to original position
    HapticFeedback.lightImpact();
  }

  void _completeInteraction() {
    setState(() {
      _currentPhase = TutorialPhase.completion;
      _isInteractionEnabled = false;
    });

    _reconstructAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _dragController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 600,
      child: Stack(
        children: [
          // Background particle effects
          _buildParticleBackground(),
          
          // Tutorial content based on type
          _buildTutorialContent(),
          
          // Interactive elements
          if (_isInteractionEnabled) _buildInteractiveElements(),
          
          // Progress indicator
          _buildProgressIndicator(),
          
          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticleSystemPainter(
            animation: _particleController,
            tutorialType: widget.type,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildTutorialContent() {
    switch (widget.type) {
      case CryptoTutorialType.secretSplitting:
        return _buildSecretSplittingAnimation();
      case CryptoTutorialType.secretReconstruction:
        return _buildSecretReconstructionAnimation();
      case CryptoTutorialType.thresholdConcept:
        return _buildThresholdConceptAnimation();
      case CryptoTutorialType.shareDistribution:
        return _buildShareDistributionAnimation();
    }
  }

  Widget _buildSecretSplittingAnimation() {
    return AnimatedBuilder(
      animation: _splitAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Original secret
            Positioned(
              left: 150,
              top: 50,
              child: Transform.scale(
                scale: 1.0 - (_splitAnimation.value * 0.3),
                child: Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.blue.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            
            // Split arrow
            if (_splitAnimation.value > 0.2)
              Positioned(
                left: 180,
                top: 150,
                child: Opacity(
                  opacity: (_splitAnimation.value - 0.2) * 2,
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            
            // Generated shares
            ..._draggableShares.asMap().entries.map((entry) {
              final index = entry.key;
              final share = entry.value;
              final delay = index * 0.1;
              final progress = (_splitAnimation.value - delay).clamp(0.0, 1.0);
              
              return Positioned(
                left: share.position.dx + (progress * 50),
                top: share.position.dy + (progress * 20),
                child: Transform.scale(
                  scale: progress,
                  child: Opacity(
                    opacity: progress,
                    child: _buildShareWidget(share),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSecretReconstructionAnimation() {
    return Stack(
      children: [
        // Share slots
        ..._shareSlots.map((slot) => _buildShareSlot(slot)),
        
        // Draggable shares
        ..._draggableShares.map((share) => _buildDraggableShare(share)),
        
        // Reconstruction result
        if (_currentPhase == TutorialPhase.completion)
          _buildReconstructionResult(),
      ],
    );
  }

  Widget _buildThresholdConceptAnimation() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Threshold: 3 of 5',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // Visual representation of threshold
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index < (3 * _mainController.value).ceil();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Need any 3 shares to reconstruct',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareDistributionAnimation() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final progress = _mainController.value;
        
        return Stack(
          children: [
            // Central share
            Positioned(
              left: 200,
              top: 200,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue,
                      Colors.blue.withValues(alpha: 0.6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            
            // Distribution paths
            ...List.generate(5, (index) {
              final angle = (index * 72) * (math.pi / 180);
              final radius = 120.0;
              final x = 240 + (radius * math.cos(angle));
              final y = 240 + (radius * math.sin(angle));
              
              return AnimatedPositioned(
                duration: Duration(milliseconds: (1000 + index * 200)),
                left: 200 + ((x - 200) * progress),
                top: 200 + ((y - 200) * progress),
                child: Opacity(
                  opacity: progress,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getDistributionColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getDistributionIcon(index),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildInteractiveElements() {
    return Stack(
      children: _draggableShares.map((share) => _buildDraggableShare(share)).toList(),
    );
  }

  Widget _buildDraggableShare(DraggableShare share) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: share.position.dx,
      top: share.position.dy,
      child: Draggable<DraggableShare>(
        data: share,
        feedback: _buildShareWidget(share, isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildShareWidget(share),
        ),
        onDragEnd: (details) {
          _onShareDragEnd(share, details.offset);
        },
        child: _buildShareWidget(share),
      ),
    );
  }

  Widget _buildShareWidget(DraggableShare share, {bool isDragging = false}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isDragging ? 1.1 : (1.0 + (_pulseController.value * 0.1));
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  share.color,
                  share.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: share.color.withValues(alpha: 0.3),
                  blurRadius: isDragging ? 20 : 10,
                  offset: Offset(0, isDragging ? 8 : 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                share.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareSlot(ShareSlot slot) {
    final isOccupied = slot.occupiedBy != null;
    
    return Positioned(
      left: slot.position.dx - 40,
      top: slot.position.dy - 30,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(
                color: isOccupied ? Colors.green : Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isOccupied 
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
            ),
            child: Center(
              child: Icon(
                isOccupied ? Icons.check_circle : Icons.add_circle_outline,
                color: isOccupied ? Colors.green : Colors.white.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReconstructionResult() {
    return AnimatedBuilder(
      animation: _reconstructAnimation,
      builder: (context, child) {
        return Positioned(
          left: 150,
          top: 500,
          child: Transform.scale(
            scale: _reconstructAnimation.value,
            child: Opacity(
              opacity: _reconstructAnimation.value,
              child: Container(
                width: 120,
                height: 80,
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
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_open,
                      color: Colors.white,
                      size: 32,
                    ),
                    Text(
                      'Secret Restored!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  Widget _buildProgressIndicator() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Text(
              'Progress: ${(_mainController.value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    String instruction;
    
    switch (widget.type) {
      case CryptoTutorialType.secretSplitting:
        instruction = 'Watch the secret split into multiple shares';
        break;
      case CryptoTutorialType.secretReconstruction:
        instruction = 'Drag shares to slots to reconstruct the secret';
        break;
      case CryptoTutorialType.thresholdConcept:
        instruction = 'Understanding the threshold concept';
        break;
      case CryptoTutorialType.shareDistribution:
        instruction = 'See how shares are distributed securely';
        break;
    }
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          instruction,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getDistributionColor(int index) {
    final colors = [
      const Color(0xFF4B7BEC),
      const Color(0xFF00D395),
      const Color(0xFF6C5CE7),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB800),
    ];
    return colors[index % colors.length];
  }

  IconData _getDistributionIcon(int index) {
    final icons = [
      Icons.home,
      Icons.account_balance,
      Icons.cloud,
      Icons.family_restroom,
      Icons.safety_check,
    ];
    return icons[index % icons.length];
  }
}

// Data Models

enum CryptoTutorialType {
  secretSplitting,
  secretReconstruction,
  thresholdConcept,
  shareDistribution,
}

enum TutorialPhase {
  introduction,
  interaction,
  completion,
}

class DraggableShare {
  final String id;
  final String content;
  final Color color;
  Offset position;

  DraggableShare({
    required this.id,
    required this.content,
    required this.color,
    required this.position,
  });
}

class ShareSlot {
  final String id;
  final Offset position;
  final String? requiredShareId;
  final bool isRequired;
  String? occupiedBy;

  ShareSlot({
    required this.id,
    required this.position,
    this.requiredShareId,
    this.isRequired = false,
    this.occupiedBy,
  });
}

// Custom Painter for Particle System
class ParticleSystemPainter extends CustomPainter {
  final Animation<double> animation;
  final CryptoTutorialType tutorialType;

  ParticleSystemPainter({
    required this.animation,
    required this.tutorialType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Generate particles based on tutorial type
    for (int i = 0; i < 30; i++) {
      final progress = (animation.value + i * 0.1) % 1.0;
      final x = (i * 43.0) % size.width;
      final y = size.height * progress;
      final opacity = (1.0 - progress) * 0.3;
      
      paint.color = _getParticleColor(tutorialType).withValues(alpha: opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        2.0 + (progress * 2.0),
        paint,
      );
    }

    // Draw connecting lines for crypto flow
    if (tutorialType == CryptoTutorialType.secretSplitting ||
        tutorialType == CryptoTutorialType.secretReconstruction) {
      _drawCryptoFlowLines(canvas, size, paint);
    }
  }

  void _drawCryptoFlowLines(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    paint.color = Colors.blue.withValues(alpha: 0.3);

    for (int i = 0; i < 8; i++) {
      final startX = (i * 80.0) % size.width;
      final startY = (animation.value * size.height + i * 50) % size.height;
      final endX = ((i + 1) * 80.0) % size.width;
      final endY = ((animation.value + 0.1) * size.height + (i + 1) * 50) % size.height;
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  Color _getParticleColor(CryptoTutorialType type) {
    switch (type) {
      case CryptoTutorialType.secretSplitting:
        return const Color(0xFF4B7BEC);
      case CryptoTutorialType.secretReconstruction:
        return const Color(0xFF00D395);
      case CryptoTutorialType.thresholdConcept:
        return const Color(0xFF6C5CE7);
      case CryptoTutorialType.shareDistribution:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  bool shouldRepaint(ParticleSystemPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}