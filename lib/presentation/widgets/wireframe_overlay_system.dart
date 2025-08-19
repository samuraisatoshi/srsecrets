import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wireframe Overlay System for Interactive UI Guidance
/// Provides white lines, tooltips, animated arrows, and progressive disclosure
class WireframeOverlaySystem extends StatefulWidget {
  final Widget child;
  final List<WireframeElement> elements;
  final bool isActive;
  final VoidCallback? onComplete;
  final Duration animationDuration;
  final bool showProgressIndicator;

  const WireframeOverlaySystem({
    super.key,
    required this.child,
    required this.elements,
    this.isActive = false,
    this.onComplete,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showProgressIndicator = true,
  });

  @override
  State<WireframeOverlaySystem> createState() => _WireframeOverlaySystemState();
}

class _WireframeOverlaySystemState extends State<WireframeOverlaySystem>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _progressController;
  late AnimationController _arrowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentElementIndex = 0;
  bool _isSystemActive = false;
  List<GlobalKey> _elementKeys = [];
  final Map<String, Rect> _elementBounds = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeKeys();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _arrowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializeKeys() {
    _elementKeys = List.generate(
      widget.elements.length,
      (index) => GlobalKey(),
    );
  }

  @override
  void didUpdateWidget(WireframeOverlaySystem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startWireframeSystem();
      } else {
        _stopWireframeSystem();
      }
    }
    
    if (widget.elements.length != oldWidget.elements.length) {
      _initializeKeys();
      if (_isSystemActive) {
        _resetToFirstElement();
      }
    }
  }

  void _startWireframeSystem() {
    if (!mounted) return;
    
    setState(() {
      _isSystemActive = true;
      _currentElementIndex = 0;
    });

    _calculateElementBounds();
    _mainController.forward();
    _progressController.forward();
    _arrowController.repeat();
    
    HapticFeedback.lightImpact();
  }

  void _stopWireframeSystem() {
    if (!mounted) return;

    setState(() {
      _isSystemActive = false;
    });

    _mainController.reverse();
    _progressController.reset();
    _arrowController.stop();
  }

  void _calculateElementBounds() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < widget.elements.length; i++) {
        final element = widget.elements[i];
        if (element.targetKey?.currentContext != null) {
          final RenderBox renderBox = element.targetKey!.currentContext!
              .findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          
          _elementBounds[element.id] = Rect.fromLTWH(
            position.dx,
            position.dy,
            size.width,
            size.height,
          );
        }
      }
      
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _nextElement() {
    if (_currentElementIndex < widget.elements.length - 1) {
      setState(() {
        _currentElementIndex++;
      });
      _progressController.reset();
      _progressController.forward();
      HapticFeedback.selectionClick();
    } else {
      _completeWireframeSystem();
    }
  }

  void _previousElement() {
    if (_currentElementIndex > 0) {
      setState(() {
        _currentElementIndex--;
      });
      _progressController.reset();
      _progressController.forward();
      HapticFeedback.selectionClick();
    }
  }

  void _resetToFirstElement() {
    setState(() {
      _currentElementIndex = 0;
    });
    _progressController.reset();
    _progressController.forward();
  }

  void _completeWireframeSystem() {
    _stopWireframeSystem();
    widget.onComplete?.call();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _progressController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isSystemActive) _buildWireframeOverlay(context),
      ],
    );
  }

  Widget _buildWireframeOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _progressController, _arrowController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.7),
            child: Stack(
              children: [
                // Wireframe lines and highlights
                CustomPaint(
                  painter: WireframePainter(
                    elements: widget.elements,
                    currentIndex: _currentElementIndex,
                    progress: _progressController.value,
                    arrowProgress: _arrowController.value,
                    elementBounds: _elementBounds,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                ),
                
                // Interactive tooltip
                if (_currentElementIndex < widget.elements.length)
                  _buildElementTooltip(
                    widget.elements[_currentElementIndex],
                    theme,
                    isDark,
                  ),
                
                // Progress indicator
                if (widget.showProgressIndicator)
                  _buildProgressIndicator(theme, isDark),
                
                // Navigation controls
                _buildNavigationControls(theme, isDark),
                
                // Skip button
                _buildSkipButton(theme, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildElementTooltip(
    WireframeElement element,
    ThemeData theme,
    bool isDark,
  ) {
    final bounds = _elementBounds[element.id];
    if (bounds == null) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = 280.0;
    final tooltipHeight = element.description != null ? 140.0 : 80.0;
    
    // Calculate optimal tooltip position
    double left = bounds.center.dx - (tooltipWidth / 2);
    double top = bounds.bottom + 16;
    
    // Adjust for screen boundaries
    if (left < 16) left = 16;
    if (left + tooltipWidth > screenSize.width - 16) {
      left = screenSize.width - tooltipWidth - 16;
    }
    
    if (top + tooltipHeight > screenSize.height - 100) {
      top = bounds.top - tooltipHeight - 16;
    }

    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Positioned(
        left: left,
        top: top,
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: element.color ?? Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      element.icon ?? Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      element.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (element.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  element.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentElementIndex + 1} of ${widget.elements.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      if (_currentElementIndex > 0)
                        IconButton(
                          onPressed: _previousElement,
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 16,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _nextElement,
                        icon: Icon(_currentElementIndex < widget.elements.length - 1
                            ? Icons.arrow_forward
                            : Icons.check),
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, bool isDark) {
    return Positioned(
      top: 60,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.black.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(widget.elements.length, (index) {
              final isActive = index == _currentElementIndex;
              final isPrevious = index < _currentElementIndex;
              
              return Container(
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive || isPrevious
                      ? Colors.blue
                      : Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(ThemeData theme, bool isDark) {
    return Positioned(
      bottom: 40,
      right: 20,
      child: Row(
        children: [
          if (_currentElementIndex > 0)
            FloatingActionButton.small(
              onPressed: _previousElement,
              heroTag: 'previous',
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              child: const Icon(Icons.arrow_back),
            ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _nextElement,
            heroTag: 'next',
            child: Icon(_currentElementIndex < widget.elements.length - 1
                ? Icons.arrow_forward
                : Icons.check),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(ThemeData theme, bool isDark) {
    return Positioned(
      top: 60,
      right: 20,
      child: TextButton(
        onPressed: _completeWireframeSystem,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: isDark 
              ? Colors.black.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

/// Wireframe Element Definition
class WireframeElement {
  final String id;
  final String title;
  final String? description;
  final IconData? icon;
  final Color? color;
  final GlobalKey? targetKey;
  final WireframeType type;
  final bool showArrow;
  final ArrowDirection arrowDirection;

  WireframeElement({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.color,
    this.targetKey,
    this.type = WireframeType.highlight,
    this.showArrow = true,
    this.arrowDirection = ArrowDirection.down,
  });
}

enum WireframeType {
  highlight,
  outline,
  spotlight,
  pulse,
}

enum ArrowDirection {
  up,
  down,
  left,
  right,
}

/// Custom Painter for Wireframe Effects
class WireframePainter extends CustomPainter {
  final List<WireframeElement> elements;
  final int currentIndex;
  final double progress;
  final double arrowProgress;
  final Map<String, Rect> elementBounds;
  final bool isDark;

  WireframePainter({
    required this.elements,
    required this.currentIndex,
    required this.progress,
    required this.arrowProgress,
    required this.elementBounds,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentIndex >= elements.length) return;

    final element = elements[currentIndex];
    final bounds = elementBounds[element.id];
    
    if (bounds == null) return;

    switch (element.type) {
      case WireframeType.highlight:
        _drawHighlight(canvas, bounds, element);
        break;
      case WireframeType.outline:
        _drawOutline(canvas, bounds, element);
        break;
      case WireframeType.spotlight:
        _drawSpotlight(canvas, size, bounds, element);
        break;
      case WireframeType.pulse:
        _drawPulse(canvas, bounds, element);
        break;
    }

    if (element.showArrow) {
      _drawAnimatedArrow(canvas, bounds, element);
    }
  }

  void _drawHighlight(Canvas canvas, Rect bounds, WireframeElement element) {
    final paint = Paint()
      ..color = (element.color ?? Colors.blue).withValues(alpha: 0.3 * progress)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      borderPaint,
    );
  }

  void _drawOutline(Canvas canvas, Rect bounds, WireframeElement element) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      paint,
    );
  }

  void _drawSpotlight(Canvas canvas, Size size, Rect bounds, WireframeElement element) {
    final center = bounds.center;
    final radius = math.max(bounds.width, bounds.height) * 0.6;

    final gradient = RadialGradient(
      center: Alignment.center,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.3 * progress),
        Colors.black.withValues(alpha: 0.8 * progress),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  void _drawPulse(Canvas canvas, Rect bounds, WireframeElement element) {
    final center = bounds.center;
    final maxRadius = math.max(bounds.width, bounds.height) * 0.8;
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = (element.color ?? Colors.blue).withValues(alpha: (1 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawAnimatedArrow(Canvas canvas, Rect bounds, WireframeElement element) {
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final arrowOffset = 20.0 + (10.0 * math.sin(arrowProgress * 2 * math.pi));
    
    Offset start, end, arrowTip1, arrowTip2;
    
    switch (element.arrowDirection) {
      case ArrowDirection.down:
        start = Offset(bounds.center.dx, bounds.bottom + arrowOffset);
        end = Offset(bounds.center.dx, bounds.bottom + arrowOffset + 30);
        arrowTip1 = Offset(end.dx - 8, end.dy - 8);
        arrowTip2 = Offset(end.dx + 8, end.dy - 8);
        break;
      case ArrowDirection.up:
        start = Offset(bounds.center.dx, bounds.top - arrowOffset);
        end = Offset(bounds.center.dx, bounds.top - arrowOffset - 30);
        arrowTip1 = Offset(end.dx - 8, end.dy + 8);
        arrowTip2 = Offset(end.dx + 8, end.dy + 8);
        break;
      case ArrowDirection.left:
        start = Offset(bounds.left - arrowOffset, bounds.center.dy);
        end = Offset(bounds.left - arrowOffset - 30, bounds.center.dy);
        arrowTip1 = Offset(end.dx + 8, end.dy - 8);
        arrowTip2 = Offset(end.dx + 8, end.dy + 8);
        break;
      case ArrowDirection.right:
        start = Offset(bounds.right + arrowOffset, bounds.center.dy);
        end = Offset(bounds.right + arrowOffset + 30, bounds.center.dy);
        arrowTip1 = Offset(end.dx - 8, end.dy - 8);
        arrowTip2 = Offset(end.dx - 8, end.dy + 8);
        break;
    }

    canvas.drawLine(start, end, arrowPaint);
    canvas.drawLine(end, arrowTip1, arrowPaint);
    canvas.drawLine(end, arrowTip2, arrowPaint);
  }

  @override
  bool shouldRepaint(WireframePainter oldDelegate) {
    return progress != oldDelegate.progress ||
           arrowProgress != oldDelegate.arrowProgress ||
           currentIndex != oldDelegate.currentIndex;
  }
}