import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/premium_theme.dart';

/// Premium PIN input widget matching Trezor/Ledger design standards
class PremiumPinInput extends StatefulWidget {
  final Function(String) onCompleted;
  final bool isLoading;
  final int minLength;
  final int maxLength;
  final String? errorMessage;
  final bool isSetupMode;

  const PremiumPinInput({
    super.key,
    required this.onCompleted,
    this.isLoading = false,
    this.minLength = 4,
    this.maxLength = 8,
    this.errorMessage,
    this.isSetupMode = false,
  });

  @override
  State<PremiumPinInput> createState() => _PremiumPinInputState();
}

class _PremiumPinInputState extends State<PremiumPinInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _pin = '';
  bool _canSubmit = false;
  
  // Animation controllers
  late AnimationController _dotAnimationController;
  late AnimationController _errorAnimationController;
  late AnimationController _successAnimationController;
  final List<AnimationController> _keyAnimationControllers = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Initialize key animation controllers
    for (int i = 0; i < 12; i++) {
      _keyAnimationControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: this,
        ),
      );
    }
    
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    _errorAnimationController.dispose();
    _successAnimationController.dispose();
    for (var controller in _keyAnimationControllers) {
      controller.dispose();
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final oldLength = _pin.length;
    setState(() {
      _pin = _controller.text;
      _canSubmit = _pin.length >= widget.minLength && _pin.length <= widget.maxLength;
    });
    
    // Animate dot when PIN digit is added
    if (_pin.length > oldLength) {
      _dotAnimationController.forward().then((_) {
        _dotAnimationController.reverse();
      });
    }
  }

  void _submitPin() {
    if (_canSubmit && !widget.isLoading) {
      _successAnimationController.forward();
      HapticFeedback.mediumImpact();
      widget.onCompleted(_pin);
      if (!widget.isSetupMode) {
        // Use post frame callback instead of Future.delayed to avoid timer issues in tests
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.clear();
            setState(() {
              _pin = '';
              _canSubmit = false;
            });
            _successAnimationController.reset();
          }
        });
      }
    }
  }

  void _onKeyPressed(String key, int index) {
    if (widget.isLoading) return;
    
    // Animate key press
    _keyAnimationControllers[index].forward().then((_) {
      _keyAnimationControllers[index].reverse();
    });
    
    HapticFeedback.lightImpact();

    if (key == 'backspace') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
        });
        _controller.text = _pin;
      }
    } else if (key == 'clear') {
      setState(() {
        _pin = '';
      });
      _controller.clear();
      _errorAnimationController.forward().then((_) {
        _errorAnimationController.reverse();
      });
    } else if (key == 'enter') {
      _submitPin();
    } else if (RegExp(r'^\d$').hasMatch(key) && _pin.length < widget.maxLength) {
      setState(() {
        _pin = _pin + key;
        _canSubmit = _pin.length >= widget.minLength;
      });
      _controller.text = _pin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Column(
        children: [
        // Hidden text field - SECURITY: readOnly prevents keyboard access
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: true, // CRITICAL: Prevents device keyboard from appearing
              showCursor: false, // Hide cursor for security
              enableInteractiveSelection: false, // Prevent text selection
              keyboardType: TextInputType.none, // Explicitly disable keyboard
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.maxLength),
              ],
            ),
          ),
        ),
        
        // Premium PIN dots display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: PremiumTheme.getGlassMorphism(isDark: isDark),
          child: Column(
            children: [
              // Security indicator and length requirement
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE PIN ENTRY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.minLength}-${widget.maxLength} digits required • ${_pin.length} entered',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _canSubmit 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // PIN dots with animations - Responsive layout
              Semantics(
                label: 'PIN entry: ${_pin.length} of ${widget.maxLength} digits entered',
                liveRegion: true,
                child: ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive dot size based on available width
                      final availableWidth = constraints.maxWidth - 32; // Account for padding
                      final maxDotWidth = availableWidth / widget.maxLength;
                      final dotSize = maxDotWidth > 44 ? 24.0 : 
                                     maxDotWidth > 36 ? 20.0 : 16.0;
                      final dotMargin = maxDotWidth > 44 ? 10.0 : 
                                       maxDotWidth > 36 ? 8.0 : 6.0;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.maxLength,
                          (index) => AnimatedBuilder(
                            animation: _dotAnimationController,
                            builder: (context, child) {
                              final scale = index == _pin.length - 1
                                  ? 1.0 + (_dotAnimationController.value * 0.3)
                                  : 1.0;
                              
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: dotMargin),
                                  width: dotSize,
                                  height: dotSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: index < _pin.length
                                    ? LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.tertiary,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: index < _pin.length
                                    ? null
                                    : isDark
                                        ? const Color(0xFF2A3142).withValues(alpha: 0.5)
                                        : const Color(0xFFE2E8F0),
                                border: Border.all(
                                  color: index < _pin.length
                                      ? Colors.transparent
                                      : isDark
                                          ? const Color(0xFF3A4357).withValues(alpha: 0.3)
                                          : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: index < _pin.length
                                    ? [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                    },
                  ),
                ),
              ),
              
              // Progress indicator
              const SizedBox(height: 16),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: isDark
                      ? const Color(0xFF2A3142).withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _pin.length / widget.maxLength,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Premium keypad or loading
        if (widget.isLoading) ...[
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifying PIN...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          _buildPremiumKeypad(context, isDark),
        ],
        
        // Error message if present
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _errorAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _errorAnimationController.value * 10 *
                      (1 - _errorAnimationController.value) *
                      4,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    ),
    );
  }

  Widget _buildPremiumKeypad(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Submit button
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _canSubmit && !widget.isLoading ? _submitPin : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSubmit 
                ? theme.colorScheme.primary 
                : theme.colorScheme.surfaceContainerHighest,
              foregroundColor: _canSubmit
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _canSubmit ? 2 : 0,
            ),
            icon: Icon(
              _canSubmit ? Icons.lock_open : Icons.lock_outline,
              size: 20,
            ),
            label: Text(
              _canSubmit 
                ? (widget.isSetupMode ? 'Set PIN' : 'Unlock')
                : 'Enter ${widget.minLength}+ digits',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Keypad
        _buildKeypadGrid(context, isDark),
      ],
    );
  }

  Widget _buildKeypadGrid(BuildContext context, bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['clear', '0', 'backspace'],
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? const Color(0xFF141824).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
      ),
      child: Column(
        children: [
          for (int row = 0; row < keys.length; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < keys[row].length; col++)
                    _buildPremiumKey(
                      context,
                      keys[row][col],
                      row * 3 + col,
                      isDark,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumKey(
    BuildContext context,
    String key,
    int index,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    IconData? icon;
    String semanticLabel;
    
    if (key == 'clear') {
      icon = Icons.clear_all_rounded;
      semanticLabel = 'Clear all digits';
    } else if (key == 'backspace') {
      icon = Icons.backspace_outlined;
      semanticLabel = 'Delete last digit';
    } else {
      semanticLabel = 'Enter digit $key';
    }
    
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !widget.isLoading,
      child: AnimatedBuilder(
        animation: _keyAnimationControllers[index],
        builder: (context, child) {
          final scale = 1.0 - (_keyAnimationControllers[index].value * 0.05);
          
          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading
                    ? null
                    : () => _onKeyPressed(key, index),
                borderRadius: BorderRadius.circular(16),
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1C2333),
                              const Color(0xFF2A3142).withValues(alpha: 0.8),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFF8FAFC),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A4357).withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: icon != null
                        ? Icon(
                            icon,
                            color: theme.colorScheme.onSurface,
                            size: 28,
                          )
                        : Text(
                            key,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}