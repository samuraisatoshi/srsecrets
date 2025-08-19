# SRSecrets UI Component Library

## Overview

This comprehensive component library documents all UI widgets and components used in the SRSecrets application. Each component is designed with security, accessibility, and premium aesthetics in mind, following the established design system and security-first principles.

## Component Hierarchy

### Foundation Components
- **PremiumSecurityCard**: Base container for security-sensitive content
- **ResponsiveLayout**: Layout wrapper handling responsive behavior
- **SecurityStateIndicator**: Visual feedback for security states
- **AccessibilityWrapper**: Accessibility enhancements for all components

### Input Components
- **PremiumPinInput**: Secure PIN entry with custom keypad
- **SecureTextInput**: Privacy-focused text input fields
- **ThresholdConfigWidget**: Shamir threshold configuration
- **ShareInputWidget**: Share value input with validation

### Display Components
- **SecretFormHeader**: Screen headers with security context
- **ShareCardWidget**: Display individual shares
- **ErrorDisplayWidget**: Secure error presentation
- **LoadingIndicator**: Security operation progress display

## Foundation Components

### PremiumSecurityCard

The cornerstone component for all security-sensitive UI elements.

#### Basic Usage
```dart
PremiumSecurityCard(
  title: "Secure Operation",
  icon: Icons.shield,
  showSecurityBadge: true,
  isElevated: true,
  child: YourContentWidget(),
)
```

#### API Reference
```dart
class PremiumSecurityCard extends StatefulWidget {
  /// Title displayed at the top of the card
  final String? title;
  
  /// Icon displayed next to the title
  final IconData? icon;
  
  /// Custom gradient colors for the card background
  final List<Color>? gradientColors;
  
  /// Whether to apply elevated shadow effect
  final bool isElevated;
  
  /// Whether to show the "SECURED" badge
  final bool showSecurityBadge;
  
  /// Callback when card is tapped (if interactive)
  final VoidCallback? onTap;
  
  /// Custom padding for the card content
  final EdgeInsetsGeometry? padding;
  
  /// The main content of the card
  final Widget child;
  
  const PremiumSecurityCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.gradientColors,
    this.isElevated = false,
    this.showSecurityBadge = false,
    this.onTap,
    this.padding,
  });
}
```

#### Visual States
```dart
// Default card with minimal elevation
PremiumSecurityCard(
  child: Text('Basic content'),
)

// Elevated card with security badge
PremiumSecurityCard(
  isElevated: true,
  showSecurityBadge: true,
  child: Text('Secure content'),
)

// Interactive card with custom styling
PremiumSecurityCard(
  title: 'Interactive Card',
  icon: Icons.touch_app,
  onTap: () => handleCardTap(),
  gradientColors: [Colors.blue.shade700, Colors.blue.shade500],
  child: Text('Tap me'),
)
```

#### Accessibility Features
- **Semantic Role**: Automatically identifies as container or button
- **Touch Targets**: Minimum 48dp when interactive
- **Focus Indicators**: Custom focus styling for keyboard navigation
- **Screen Reader**: Proper announcement of security states

### ResponsiveLayout

Wrapper component that handles responsive behavior across different screen sizes.

#### Basic Usage
```dart
ResponsiveLayout(
  mobile: MobileLayoutWidget(),
  tablet: TabletLayoutWidget(),
  desktop: DesktopLayoutWidget(),
)
```

#### API Reference
```dart
class ResponsiveLayout extends StatelessWidget {
  /// Widget displayed on mobile devices (< 600dp)
  final Widget mobile;
  
  /// Widget displayed on tablet devices (600dp - 1200dp)
  final Widget? tablet;
  
  /// Widget displayed on desktop devices (>= 1200dp)
  final Widget? desktop;
  
  /// Custom breakpoint override
  final double? customBreakpoint;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.customBreakpoint,
  });
}
```

#### Implementation Pattern
```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      
      if (width >= (customBreakpoint ?? 1200) && desktop != null) {
        return desktop!;
      } else if (width >= 600 && tablet != null) {
        return tablet!;
      } else {
        return mobile;
      }
    },
  );
}
```

### SecurityStateIndicator

Visual component that communicates security states to users.

#### Basic Usage
```dart
SecurityStateIndicator(
  state: SecurityState.secure,
  message: "Operation completed successfully",
)
```

#### API Reference
```dart
enum SecurityState {
  secure,      // Green: confirmed secure state
  processing,  // Blue: operation in progress
  warning,     // Amber: requires user attention
  danger,      // Red: security risk or error
  neutral,     // Gray: inactive or default state
}

class SecurityStateIndicator extends StatelessWidget {
  /// Current security state
  final SecurityState state;
  
  /// Message to display with the indicator
  final String message;
  
  /// Optional custom icon override
  final IconData? customIcon;
  
  /// Size of the indicator icon
  final double iconSize;
  
  /// Whether to show animated pulse effect
  final bool animated;
}
```

#### Visual Examples
```dart
// Success state with animation
SecurityStateIndicator(
  state: SecurityState.secure,
  message: "PIN verification successful",
  animated: true,
)

// Warning state with custom icon
SecurityStateIndicator(
  state: SecurityState.warning,
  message: "Threshold configuration requires attention",
  customIcon: Icons.settings,
)

// Processing state with larger icon
SecurityStateIndicator(
  state: SecurityState.processing,
  message: "Generating secure shares...",
  iconSize: 32.0,
  animated: true,
)
```

## Input Components

### PremiumPinInput

Secure PIN entry component with custom keypad and visual masking.

#### Basic Usage
```dart
PremiumPinInput(
  minLength: 4,
  maxLength: 8,
  onCompleted: (pin) => handlePinEntry(pin),
  isSetupMode: false,
)
```

#### API Reference
```dart
class PremiumPinInput extends StatefulWidget {
  /// Callback when PIN entry is completed
  final Function(String) onCompleted;
  
  /// Whether the component is in loading state
  final bool isLoading;
  
  /// Minimum PIN length required
  final int minLength;
  
  /// Maximum PIN length allowed
  final int maxLength;
  
  /// Error message to display
  final String? errorMessage;
  
  /// Whether this is PIN setup (vs. verification)
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
}
```

#### Security Features
- **Visual Masking**: PIN digits displayed as filled dots
- **Custom Keypad**: No access to device keyboard
- **Progressive Disclosure**: Security feedback without revealing PIN
- **Haptic Feedback**: Tactile responses for better UX
- **Screen Reader Safety**: Announces count without revealing digits

#### Animation States
```dart
// Entry animation for each digit
AnimationController _dotAnimationController = AnimationController(
  duration: const Duration(milliseconds: 300),
  vsync: this,
);

// Error shake animation
Transform.translate(
  offset: Offset(
    _errorAnimationController.value * 10 * 
    (1 - _errorAnimationController.value) * 4,
    0,
  ),
  child: errorWidget,
)

// Success pulse animation
Transform.scale(
  scale: 1.0 + (_successAnimationController.value * 0.1),
  child: successWidget,
)
```

### SecureTextInput

Privacy-focused text input for sensitive data entry.

#### Basic Usage
```dart
SecureTextInput(
  label: "Secret Message",
  hint: "Enter your secret to be shared",
  onChanged: (value) => handleSecretInput(value),
  validator: (value) => validateSecret(value),
)
```

#### API Reference
```dart
class SecureTextInput extends StatefulWidget {
  /// Text label for the input field
  final String label;
  
  /// Placeholder text
  final String? hint;
  
  /// Callback when text changes
  final ValueChanged<String>? onChanged;
  
  /// Validation function
  final FormFieldValidator<String>? validator;
  
  /// Whether the input should be obscured
  final bool obscureText;
  
  /// Whether to show character count
  final bool showCharacterCount;
  
  /// Maximum number of characters allowed
  final int? maxLength;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Whether to show visibility toggle for obscured text
  final bool showVisibilityToggle;
}
```

#### Security Features
```dart
// Secure text obscuring with toggle
Row(
  children: [
    Expanded(
      child: TextField(
        obscureText: _obscureText,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
    ),
  ],
)

// Character count with security awareness
if (showCharacterCount && !obscureText)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      '${_controller.text.length}${maxLength != null ? '/$maxLength' : ''} characters',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  )
```

### ThresholdConfigWidget

Specialized component for configuring Shamir secret sharing thresholds.

#### Basic Usage
```dart
ThresholdConfigWidget(
  totalShares: 5,
  onThresholdChanged: (threshold) => handleThresholdChange(threshold),
  initialThreshold: 3,
)
```

#### API Reference
```dart
class ThresholdConfigWidget extends StatefulWidget {
  /// Total number of shares to be created
  final int totalShares;
  
  /// Callback when threshold value changes
  final ValueChanged<int> onThresholdChanged;
  
  /// Initial threshold value
  final int? initialThreshold;
  
  /// Whether to show explanatory help text
  final bool showHelpText;
  
  /// Minimum threshold allowed
  final int minThreshold;
  
  /// Custom validation for threshold values
  final String? Function(int threshold)? validator;
}
```

#### Visual Implementation
```dart
Widget _buildThresholdSlider(BuildContext context) {
  return Column(
    children: [
      // Visual representation of share distribution
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(totalShares, (index) {
          final isRequired = index < _currentThreshold;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isRequired ? theme.colorScheme.primary : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isRequired ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
      
      const SizedBox(height: 16),
      
      // Threshold slider
      Slider(
        value: _currentThreshold.toDouble(),
        min: minThreshold.toDouble(),
        max: totalShares.toDouble(),
        divisions: totalShares - minThreshold,
        label: '$_currentThreshold of $totalShares',
        onChanged: (value) {
          setState(() {
            _currentThreshold = value.round();
          });
          widget.onThresholdChanged(_currentThreshold);
        },
      ),
      
      // Help text
      if (showHelpText)
        Text(
          'Minimum $_currentThreshold shares needed to reconstruct the secret',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
    ],
  );
}
```

## Display Components

### SecretFormHeader

Standardized header component for forms with security context.

#### Basic Usage
```dart
SecretFormHeader(
  title: "Create Secret",
  subtitle: "Secure your data with Shamir's Secret Sharing",
  showSecurityBadge: true,
)
```

#### API Reference
```dart
class SecretFormHeader extends StatelessWidget {
  /// Primary title text
  final String title;
  
  /// Optional subtitle or description
  final String? subtitle;
  
  /// Whether to display security badge
  final bool showSecurityBadge;
  
  /// Custom icon for the header
  final IconData? icon;
  
  /// Additional actions or widgets
  final List<Widget>? actions;
  
  /// Whether to show back navigation button
  final bool showBackButton;
  
  /// Custom back button callback
  final VoidCallback? onBack;
}
```

#### Implementation Pattern
```dart
@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security badge if enabled
        if (showSecurityBadge) ...[
          SecurityBadge(text: 'SECURE OPERATION'),
          const SizedBox(height: 16),
        ],
        
        // Main header content
        Row(
          children: [
            // Back button
            if (showBackButton) ...[
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
            ],
            
            // Icon
            if (icon != null) ...[
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
            ],
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            if (actions != null) ...actions!,
          ],
        ),
      ],
    ),
  );
}
```

### ShareCardWidget

Component for displaying individual secret shares with validation.

#### Basic Usage
```dart
ShareCardWidget(
  shareIndex: 1,
  shareValue: "A1B2C3D4...",
  isValid: true,
  onTap: () => handleShareTap(1),
)
```

#### API Reference
```dart
class ShareCardWidget extends StatelessWidget {
  /// Index/number of this share (1-based)
  final int shareIndex;
  
  /// The actual share value (may be truncated for display)
  final String shareValue;
  
  /// Whether this share passes validation
  final bool? isValid;
  
  /// Whether this share is required for reconstruction
  final bool isRequired;
  
  /// Callback when share card is tapped
  final VoidCallback? onTap;
  
  /// Callback for share removal
  final VoidCallback? onRemove;
  
  /// Whether to show the full share value
  final bool showFullValue;
  
  /// Maximum characters to display when truncated
  final int maxDisplayLength;
}
```

#### Visual States
```dart
Widget _buildShareCard(BuildContext context) {
  final theme = Theme.of(context);
  Color borderColor;
  Color backgroundColor;
  IconData statusIcon;
  
  if (isValid == true) {
    borderColor = theme.colorScheme.primary;
    backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
    statusIcon = Icons.check_circle;
  } else if (isValid == false) {
    borderColor = theme.colorScheme.error;
    backgroundColor = theme.colorScheme.errorContainer.withValues(alpha: 0.1);
    statusIcon = Icons.error;
  } else {
    borderColor = theme.colorScheme.outline;
    backgroundColor = theme.colorScheme.surface;
    statusIcon = Icons.radio_button_unchecked;
  }
  
  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 2),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Share index indicator
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$shareIndex',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Share value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share $shareIndex',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDisplayValue(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Status and actions
              Column(
                children: [
                  Icon(
                    statusIcon,
                    color: borderColor,
                    size: 20,
                  ),
                  if (onRemove != null) ...[
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
                      iconSize: 16,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### ErrorDisplayWidget

Secure error presentation component with privacy protection.

#### Basic Usage
```dart
ErrorDisplayWidget(
  error: "PIN verification failed",
  severity: ErrorSeverity.warning,
  onDismiss: () => clearError(),
)
```

#### API Reference
```dart
enum ErrorSeverity {
  info,     // Informational messages
  warning,  // Warnings that need attention
  error,    // Standard error conditions
  critical, // Critical security errors
}

class ErrorDisplayWidget extends StatefulWidget {
  /// Error message to display
  final String error;
  
  /// Severity level of the error
  final ErrorSeverity severity;
  
  /// Whether this error can be dismissed
  final bool canDismiss;
  
  /// Callback when error is dismissed
  final VoidCallback? onDismiss;
  
  /// Whether to auto-dismiss after a delay
  final bool autoDismiss;
  
  /// Auto-dismiss duration
  final Duration autoDismissDelay;
  
  /// Whether this is a PIN-related error (for security sanitization)
  final bool isPinRelated;
}
```

#### Security Error Sanitization
```dart
String _sanitizeErrorMessage(String message, bool isPinRelated) {
  if (isPinRelated) {
    // Never reveal specific PIN validation details
    return 'Please check your PIN and try again';
  }
  
  // Remove any potentially sensitive technical details
  final sanitized = message
      .replaceAll(RegExp(r'[A-Fa-f0-9]{8,}'), '[REDACTED]')  // Remove hex values
      .replaceAll(RegExp(r'file://[^\s]+'), '[FILE_PATH]')    // Remove file paths
      .replaceAll(RegExp(r'stack trace:.*', dotAll: true), ''); // Remove stack traces
  
  return sanitized;
}

Widget _buildErrorContent(BuildContext context) {
  final sanitizedMessage = _sanitizeErrorMessage(widget.error, widget.isPinRelated);
  
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _getSeverityColor(widget.severity).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _getSeverityColor(widget.severity).withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(
          _getSeverityIcon(widget.severity),
          color: _getSeverityColor(widget.severity),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            sanitizedMessage,
            style: TextStyle(
              color: _getSeverityColor(widget.severity),
            ),
          ),
        ),
        if (widget.canDismiss) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.onDismiss,
            icon: const Icon(Icons.close),
            iconSize: 18,
          ),
        ],
      ],
    ),
  );
}
```

## Advanced Components

### Loading and Progress Components

#### SecureLoadingIndicator
```dart
class SecureLoadingIndicator extends StatefulWidget {
  final String operationName;
  final double? progress;
  final bool showProgress;
  
  @override
  Widget build(BuildContext context) {
    return PremiumSecurityCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated security icon
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Icon(
                  Icons.shield,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Text(
            operationName,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          
          if (showProgress && progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (showProgress) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
```

### Navigation Components

#### SecurityAwareNavigationRail
```dart
class SecurityAwareNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCompact;
  
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: isCompact 
          ? NavigationRailLabelType.selected 
          : NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: Text('Create'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.restore_outlined),
          selectedIcon: Icon(Icons.restore),
          label: Text('Restore'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      leading: _buildSecurityIndicator(context),
    );
  }
  
  Widget _buildSecurityIndicator(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shield,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SECURED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
```

## Testing Components

### Component Testing Patterns

#### Widget Test Template
```dart
group('Component Tests', () {
  testWidgets('PremiumSecurityCard displays correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PremiumTheme.getDarkTheme(),
        home: Scaffold(
          body: PremiumSecurityCard(
            title: 'Test Card',
            showSecurityBadge: true,
            child: const Text('Test Content'),
          ),
        ),
      ),
    );
    
    // Verify title is displayed
    expect(find.text('Test Card'), findsOneWidget);
    
    // Verify security badge is shown
    expect(find.text('SECURED'), findsOneWidget);
    
    // Verify content is displayed
    expect(find.text('Test Content'), findsOneWidget);
    
    // Verify accessibility
    final cardFinder = find.byType(PremiumSecurityCard);
    expect(
      tester.getSemantics(cardFinder).hasFlag(ui.SemanticsFlag.hasEnabledState),
      isTrue,
    );
  });

  testWidgets('PremiumPinInput handles input correctly', (tester) async {
    String? capturedPin;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumPinInput(
            onCompleted: (pin) => capturedPin = pin,
          ),
        ),
      ),
    );
    
    // Tap number buttons to enter PIN
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    
    // Tap submit button
    await tester.tap(find.byIcon(Icons.lock_open));
    
    await tester.pumpAndSettle();
    
    // Verify PIN was captured
    expect(capturedPin, equals('1234'));
    
    // Verify dots are displayed (not actual numbers)
    expect(find.text('1234'), findsNothing);
  });
});
```

#### Accessibility Testing
```dart
group('Accessibility Tests', () {
  testWidgets('Components meet accessibility requirements', (tester) async {
    await tester.pumpWidget(TestApp());
    
    // Test semantic labels
    expect(find.bySemanticsLabel('Secure PIN entry'), findsOneWidget);
    
    // Test touch target sizes
    final buttons = tester.widgetList<InkWell>(find.byType(InkWell));
    for (final button in buttons) {
      final size = tester.getSize(find.byWidget(button));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    
    // Test color contrast (using accessibility utils)
    final theme = Theme.of(tester.element(find.byType(MaterialApp)));
    expect(
      AccessibilityUtils.meetsWCAGAA(
        theme.colorScheme.onSurface,
        theme.colorScheme.surface,
      ),
      isTrue,
    );
  });
});
```

## Performance Optimization

### Component Optimization Strategies

#### Efficient Widget Building
```dart
class OptimizedComponent extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cache expensive calculations
        final layout = _getLayoutForConstraints(constraints);
        
        return RepaintBoundary(
          child: layout,
        );
      },
    );
  }
  
  Widget _getLayoutForConstraints(BoxConstraints constraints) {
    // Use static cache for layout calculations
    final key = '${constraints.maxWidth}_${constraints.maxHeight}';
    return _layoutCache[key] ??= _buildLayout(constraints);
  }
}
```

#### Animation Optimization
```dart
class AnimatedSecureComponent extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Only rebuild animated parts
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child, // Static child passed from above
        );
      },
      child: const StaticSecureContent(), // Built once, reused
    );
  }
}
```

## Implementation Guidelines

### Best Practices

#### Security-First Development
- **Data Privacy**: Never expose sensitive data in widget trees
- **Error Sanitization**: Always sanitize error messages before display
- **State Management**: Secure state handling with proper cleanup
- **Accessibility**: Ensure screen readers don't leak sensitive information

#### Code Quality
- **Single Responsibility**: Each component has one clear purpose
- **Composition over Inheritance**: Prefer composition for flexibility
- **Testability**: All components are easily testable
- **Documentation**: Comprehensive API documentation for all components

#### Performance
- **Efficient Rebuilds**: Minimize unnecessary widget rebuilds
- **Memory Management**: Proper disposal of controllers and listeners
- **Layout Optimization**: Efficient layout algorithms for responsive design
- **Animation Performance**: 60 FPS animations with proper optimization

---

*This component library serves as the comprehensive reference for all UI components in SRSecrets, ensuring consistency, security, and maintainability across the entire application.*