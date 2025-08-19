# SRSecrets UI Design System

## Overview

The SRSecrets UI Design System is a comprehensive set of design standards, components, and patterns that create a premium, security-focused user interface inspired by industry-leading hardware wallet applications like Trezor and Ledger. This design system prioritizes security, accessibility, and user trust while maintaining modern aesthetic appeal.

## Design Philosophy

### Security-First Approach
- **Trust Building**: Every visual element reinforces security and reliability
- **Clear Feedback**: Users always know the security state of their actions
- **Progressive Disclosure**: Complex features are revealed gradually to avoid overwhelming users
- **Air-Gapped Design**: No visual hints of network connectivity or external dependencies

### Premium Aesthetic
- **Clean Typography**: Inter font family with carefully selected weights
- **Sophisticated Color Palette**: Deep, rich colors that convey professionalism
- **Glass Morphism**: Subtle transparency effects for modern appeal
- **Gradient Accents**: Premium gradients that enhance brand identity

### Material Design 3 Foundation
- **Semantic Colors**: Proper use of Material 3 color roles
- **Dynamic Color**: Support for system color schemes
- **Typography Scale**: M3-compliant type ramp with custom refinements
- **Component Tokens**: Consistent spacing and sizing using the 4dp grid

## Color System

### Premium Color Palette

#### Dark Theme (Primary)
```dart
// Core colors
static const Color _deepBlack = Color(0xFF0A0E1A);
static const Color _richDark = Color(0xFF141824);
static const Color _midnightBlue = Color(0xFF1C2333);
static const Color _steelGray = Color(0xFF2A3142);

// Accent colors
static const Color _premiumGreen = Color(0xFF00D395);  // Success, confirmation
static const Color _securityBlue = Color(0xFF4B7BEC);  // Primary actions
static const Color _warningAmber = Color(0xFFFFAA00);  // Warnings, attention
static const Color _dangerRed = Color(0xFFFF4757);     // Errors, danger

// Text hierarchy
static const Color _textPrimary = Color(0xFFE8ECF4);
static const Color _textSecondary = Color(0xFFA8B3C8);
static const Color _textTertiary = Color(0xFF6B7A90);
```

#### Light Theme (Secondary)
```dart
// Surface colors
static const Color _surfaceLight = Color(0xFFF8FAFC);
static const Color _primaryLight = Color(0xFF4B7BEC);
static const Color _backgroundLight = Color(0xFFFFFFFF);

// Text colors (light theme)
static const Color _textDarkPrimary = Color(0xFF1E293B);
static const Color _textDarkSecondary = Color(0xFF64748B);
```

### Semantic Color Usage

#### Security States
- **Secured/Verified**: `_premiumGreen` - Indicates successful security validation
- **Processing**: `_securityBlue` - Shows active security operations
- **Warning**: `_warningAmber` - Alerts requiring user attention
- **Error/Danger**: `_dangerRed` - Critical security issues or failures

#### Interactive States
- **Primary Action**: `_securityBlue` - Main call-to-action buttons
- **Secondary Action**: `_steelGray` - Supporting actions
- **Disabled**: 30% opacity of base color
- **Pressed**: 10% white overlay for tactile feedback

### Accessibility Compliance

All color combinations meet WCAG 2.1 AA standards:
- **Normal text**: Minimum 4.5:1 contrast ratio
- **Large text**: Minimum 3:1 contrast ratio
- **Interactive elements**: Minimum 3:1 contrast against adjacent colors
- **Focus indicators**: Minimum 3:1 contrast ratio with 2px minimum thickness

## Typography System

### Font Family
**Primary**: Inter (system fallback: SF Pro Display, Roboto, system-ui)

### Type Scale

```dart
// Heading styles
static const TextStyle displayLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.2,
  height: 1.2,
);

static const TextStyle headlineLarge = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.8,
  height: 1.3,
);

static const TextStyle titleLarge = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
  height: 1.4,
);

// Body text
static const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.2,
  height: 1.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.4,
);

// Labels and captions
static const TextStyle labelLarge = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.2,
  height: 1.3,
);

static const TextStyle labelSmall = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.2,
  height: 1.2,
);
```

### Typography Usage Guidelines

#### Security-Critical Text
- **PIN Requirements**: Use `labelSmall` in uppercase for security instructions
- **Error Messages**: Use `bodyMedium` with appropriate semantic color
- **Success Confirmations**: Use `labelLarge` with premium green color

#### Informational Hierarchy
- **Screen Titles**: `headlineLarge` with primary text color
- **Section Headers**: `titleLarge` with 70% opacity
- **Body Content**: `bodyLarge` for readability
- **Helper Text**: `bodyMedium` with secondary text color

## Spacing and Layout

### 4dp Grid System
All spacing follows the Material Design 4dp grid system:

```dart
// Base spacing units
static const double xs = 4.0;   // Micro spacing
static const double sm = 8.0;   // Small spacing
static const double md = 16.0;  // Medium spacing (standard)
static const double lg = 24.0;  // Large spacing
static const double xl = 32.0;  // Extra large spacing
static const double xxl = 48.0; // Maximum spacing
```

### Layout Patterns

#### Card Padding
- **Internal Padding**: 20px (5 × 4dp grid)
- **Content Margin**: 16px (4 × 4dp grid)
- **Section Spacing**: 24px (6 × 4dp grid)

#### Form Elements
- **Field Spacing**: 16px vertical margin
- **Button Height**: 56px (14 × 4dp grid)
- **Input Height**: 56px with 18px internal padding
- **Label Margin**: 8px below label, 4px above field

## Component Architecture

### Premium Security Card

The foundation component for all security-sensitive UI elements:

```dart
PremiumSecurityCard(
  title: "Secure PIN Entry",
  icon: Icons.shield_outlined,
  showSecurityBadge: true,
  isElevated: true,
  child: // Your content here
)
```

#### Visual Properties
- **Border Radius**: 20px for premium feel
- **Elevation**: Glass morphism effect with subtle shadows
- **Border**: 1px semi-transparent border
- **Background**: Gradient from surface to variant

#### Interactive States
- **Hover**: Subtle scale animation (98% scale)
- **Pressed**: 2px downward translation
- **Focus**: 2px blue border overlay

### Premium PIN Input

Security-focused PIN entry with custom keypad:

```dart
PremiumPinInput(
  minLength: 4,
  maxLength: 8,
  isSetupMode: false,
  onCompleted: (pin) => // Handle PIN entry
)
```

#### Security Features
- **Visual Masking**: Filled circles instead of numbers
- **Custom Keypad**: No device keyboard access
- **Progress Indicator**: Visual feedback of entry progress
- **Error Animation**: Shake effect for invalid attempts

#### Accessibility Features
- **Screen Reader**: Announces digit count without revealing PIN
- **Touch Targets**: 70x70dp keypad buttons (exceeds 44dp requirement)
- **Focus Management**: Automatic focus handling
- **Semantic Labels**: Clear descriptions for all interactive elements

### Glass Morphism Effects

Premium visual treatment for elevated surfaces:

```dart
BoxDecoration getGlassMorphism({bool isDark = false}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    color: isDark 
        ? _richDark.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.9),
    border: Border.all(
      color: isDark
          ? _steelGray.withValues(alpha: 0.3)
          : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
```

## Animation Standards

### Duration Guidelines
- **Micro-interactions**: 100-150ms (button presses, focus changes)
- **Component Transitions**: 300ms (card animations, state changes)
- **Screen Transitions**: 500ms (navigation, modal presentations)
- **Loading States**: 600ms+ (PIN verification, crypto operations)

### Easing Curves
- **Responsive Interactions**: `Curves.easeInOut` for button presses
- **Organic Movement**: `Curves.easeOutCubic` for card animations
- **Attention-grabbing**: `Curves.elasticOut` for error states
- **Subtle Feedback**: `Curves.linear` for progress indicators

### Animation Patterns

#### PIN Entry Animation
```dart
// Dot scale animation on digit entry
AnimationController _dotController = AnimationController(
  duration: const Duration(milliseconds: 300),
  vsync: this,
);

// Scale from 1.0 to 1.3 and back
Animation<double> _scaleAnimation = Tween<double>(
  begin: 1.0,
  end: 1.3,
).animate(CurvedAnimation(
  parent: _dotController,
  curve: Curves.easeInOut,
));
```

#### Error Shake Animation
```dart
// Horizontal shake for errors
Transform.translate(
  offset: Offset(
    _errorController.value * 10 * 
    (1 - _errorController.value) * 4,
    0,
  ),
  child: // Error content
)
```

## Theme Integration

### Material 3 Integration

```dart
ThemeData getLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    
    colorScheme: const ColorScheme.light(
      primary: _securityBlue,
      secondary: _premiumGreen,
      tertiary: _gradientStart,
      surface: _surfaceLight,
      error: _dangerRed,
      // ... additional color mappings
    ),
    
    // Component themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
```

### Dark Theme Considerations

The dark theme is the primary visual identity:
- **Higher Contrast**: Better readability in low-light conditions
- **Battery Efficiency**: OLED-friendly dark backgrounds
- **Security Focus**: Darker UI reduces screen glare during sensitive operations
- **Premium Appeal**: Deep colors convey sophistication and security

## Implementation Guidelines

### Component Usage Patterns

#### Security-Sensitive Components
Always use `PremiumSecurityCard` wrapper:
```dart
PremiumSecurityCard(
  showSecurityBadge: true,
  isElevated: true,
  child: PremiumPinInput(
    // PIN configuration
  ),
)
```

#### Information Display
Use consistent spacing and typography:
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Title',
      style: theme.textTheme.titleLarge,
    ),
    const SizedBox(height: 8),
    Text(
      'Description',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  ],
)
```

#### Interactive Elements
Maintain consistent touch targets and feedback:
```dart
ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(88, 56), // Accessibility compliance
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
  icon: Icon(Icons.security),
  label: Text('Secure Action'),
  onPressed: () => // Handle action
)
```

### Performance Considerations

#### Efficient Gradient Usage
Cache gradient objects to avoid recreation:
```dart
static final LinearGradient _premiumGradient = LinearGradient(
  colors: [_gradientStart, _gradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

#### Animation Optimization
Dispose controllers properly to prevent memory leaks:
```dart
@override
void dispose() {
  _animationController.dispose();
  super.dispose();
}
```

## Testing Integration

### Widget Testing Patterns
Test components with accessibility features:
```dart
testWidgets('Premium PIN input maintains accessibility', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PremiumPinInput(
          onCompleted: (pin) {},
        ),
      ),
    ),
  );

  // Test semantic labels
  expect(find.bySemanticsLabel('PIN entry'), findsOneWidget);
  
  // Test touch target sizes
  final button = tester.getSize(find.text('1'));
  expect(button.width, greaterThanOrEqualTo(44));
  expect(button.height, greaterThanOrEqualTo(44));
});
```

### Golden File Testing
Capture visual regression baselines:
```dart
testWidgets('Premium card matches golden file', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PremiumTheme.getDarkTheme(),
      home: Material(
        child: PremiumSecurityCard(
          title: 'Test Card',
          child: Text('Content'),
        ),
      ),
    ),
  );

  await expectLater(
    find.byType(PremiumSecurityCard),
    matchesGoldenFile('premium_card_dark.png'),
  );
});
```

## Future Enhancements

### Planned Features
- **Custom Icons**: Security-specific icon library
- **Advanced Animations**: Particle effects for success states
- **Haptic Feedback**: Enhanced tactile responses
- **Biometric Integration**: Visual feedback for biometric auth
- **Multi-theme Support**: Additional brand variations

### Extensibility
The design system is built for extension:
- **Color Tokens**: Easy theme customization
- **Component Inheritance**: Base classes for custom components
- **Animation Library**: Reusable animation patterns
- **Responsive Utilities**: Screen-size-aware component variants

## Resources

### Design References
- **Trezor Suite**: Hardware wallet interface inspiration
- **Ledger Live**: Premium crypto wallet design patterns
- **Material Design 3**: Foundation system and components
- **Inter Font**: Typography system and character sets

### Development Tools
- **Flutter Inspector**: Component hierarchy debugging
- **Accessibility Scanner**: WCAG compliance validation
- **Golden Toolkit**: Visual regression testing
- **Device Preview**: Multi-device responsive testing

---

*This design system documentation is maintained by the SRSecrets UX/UI team and follows the project's SOLID principles and DDD architecture.*