import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final bool isLoading;
  final int minLength;
  final int maxLength;
  final bool isSetupMode;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.isLoading = false,
    this.minLength = 4,
    this.maxLength = 8,
    this.isSetupMode = false,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _pin = '';
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _pin = _controller.text;
      _canSubmit = _pin.length >= widget.minLength && _pin.length <= widget.maxLength;
    });
  }

  void _submitPin() {
    if (_canSubmit && !widget.isLoading) {
      widget.onCompleted(_pin);
      if (!widget.isSetupMode) {
        _controller.clear();
        setState(() {
          _pin = '';
          _canSubmit = false;
        });
      }
    }
  }

  void _onKeyPressed(String key) {
    if (widget.isLoading) return;

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
    
    return Column(
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
        // PIN requirements display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.minLength}-${widget.maxLength} digits required • ${_pin.length} entered',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _canSubmit 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // PIN display dots - Responsive layout
        Semantics(
          label: 'PIN entry: ${_pin.length} of ${widget.maxLength} digits entered',
          liveRegion: true,
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive dot size based on available width
                final availableWidth = constraints.maxWidth - 32; // Account for padding
                final maxDotWidth = availableWidth / widget.maxLength;
                final dotSize = maxDotWidth > 40 ? 20.0 : 
                               maxDotWidth > 32 ? 16.0 : 14.0;
                final dotMargin = maxDotWidth > 40 ? 8.0 : 
                                 maxDotWidth > 32 ? 6.0 : 4.0;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.maxLength,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: dotMargin),
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              _canSubmit ? Icons.check_circle : Icons.lock_outline,
              size: 20,
            ),
            label: Text(
              _canSubmit 
                ? (widget.isSetupMode ? 'Set PIN' : 'Continue')
                : 'Enter ${widget.minLength}+ digits',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Custom numeric keypad
        if (widget.isLoading) ...[
          const CircularProgressIndicator(),
        ] else ...[
          _buildKeypad(context),
        ],
      ],
    );
  }

  Widget _buildKeypad(BuildContext context) {
    
    return Column(
      children: [
        // Number rows
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildKeyButton(
                    context,
                    (row * 3 + col).toString(),
                  ),
              ],
            ),
          ),
        // Bottom row with 0 and controls
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeyButton(context, 'clear', icon: Icons.clear_all),
              _buildKeyButton(context, '0'),
              _buildKeyButton(context, 'backspace', icon: Icons.backspace),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyButton(BuildContext context, String key, {IconData? icon}) {
    final theme = Theme.of(context);
    String semanticLabel;
    String? semanticHint;
    
    if (key == 'clear') {
      semanticLabel = 'Clear all digits';
      semanticHint = 'Removes all entered PIN digits';
    } else if (key == 'backspace') {
      semanticLabel = 'Delete last digit';
      semanticHint = 'Removes the last entered digit';
    } else {
      semanticLabel = 'Enter digit $key';
      semanticHint = 'Adds digit $key to PIN entry';
    }
    
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: !widget.isLoading,
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.isLoading ? null : () => _onKeyPressed(key),
          child: Container(
            width: 72, // Good size for touch targets
            height: 72, // Good size for touch targets
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28, // Increased for better visibility
                    )
                  : Text(
                      key,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}