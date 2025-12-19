/// Premium Keypad Widget
///
/// Secure numeric keypad component for PIN entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Callback type for keypad presses
typedef KeypadCallback = void Function(String key, int index);

/// Premium numeric keypad widget
class PremiumKeypad extends StatefulWidget {
  final KeypadCallback onKeyPressed;
  final bool isEnabled;
  final bool showSubmitButton;
  final bool canSubmit;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool isSetupMode;

  const PremiumKeypad({
    super.key,
    required this.onKeyPressed,
    this.isEnabled = true,
    this.showSubmitButton = true,
    this.canSubmit = false,
    this.submitLabel = 'Unlock',
    this.onSubmit,
    this.isSetupMode = false,
  });

  @override
  State<PremiumKeypad> createState() => _PremiumKeypadState();
}

class _PremiumKeypadState extends State<PremiumKeypad>
    with TickerProviderStateMixin {
  final List<AnimationController> _keyAnimationControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 12; i++) {
      _keyAnimationControllers.add(
        AnimationController(
          duration: const Duration(milliseconds: 100),
          vsync: this,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _keyAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleKeyPress(String key, int index) {
    if (!widget.isEnabled) return;

    _keyAnimationControllers[index].forward().then((_) {
      _keyAnimationControllers[index].reverse();
    });

    HapticFeedback.lightImpact();
    widget.onKeyPressed(key, index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        if (widget.showSubmitButton) ...[
          _buildSubmitButton(context, theme),
          const SizedBox(height: 16),
        ],
        _buildKeypadGrid(context, isDark),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: widget.canSubmit && widget.isEnabled ? widget.onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.canSubmit
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: widget.canSubmit
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: widget.canSubmit ? 2 : 0,
        ),
        icon: Icon(
          widget.canSubmit ? Icons.lock_open : Icons.lock_outline,
          size: 20,
        ),
        label: Text(
          widget.canSubmit
              ? (widget.isSetupMode ? 'Set PIN' : widget.submitLabel)
              : 'Enter 4+ digits',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
                    _buildKey(
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

  Widget _buildKey(
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
      enabled: widget.isEnabled,
      child: AnimatedBuilder(
        animation: _keyAnimationControllers[index],
        builder: (context, child) {
          final scale = 1.0 - (_keyAnimationControllers[index].value * 0.05);

          return Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isEnabled
                    ? () => _handleKeyPress(key, index)
                    : null,
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
