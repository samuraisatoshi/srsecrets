# SRSecrets Security UI Patterns Guide

## Overview

This guide documents the security-focused UI design patterns implemented in SRSecrets, ensuring that every visual element reinforces trust, security, and user confidence. These patterns are specifically designed for air-gapped, cryptographic applications where security is paramount and user trust is essential.

## Security-First Design Philosophy

### Core Security Principles

#### Trust Through Transparency
- **Clear Security States**: Users always understand the security level of their current action
- **Visual Security Indicators**: Consistent iconography and color coding for security states
- **Progressive Disclosure**: Complex security features revealed gradually to prevent overwhelm
- **No Hidden Processes**: All security operations provide clear visual feedback

#### Defensive UI Design
- **Prevent Accidental Actions**: Critical actions require deliberate user interaction
- **Secure by Default**: Most secure option is always the default choice
- **Clear Consequences**: Users understand the implications of security-related actions
- **Recovery Pathways**: Clear escape routes and undo mechanisms where appropriate

#### Air-Gapped Security
- **No Network Indicators**: UI never suggests or enables network connectivity
- **Local-Only Operations**: All visual feedback reinforces local-only processing
- **Device-Centric Security**: Security indicators focus on device-level protection
- **Offline-First Messaging**: All text and feedback assumes offline operation

## Visual Security Language

### Security State Colors

#### Primary Security States
```dart
// Security state color definitions
static const Color _secureGreen = Color(0xFF00D395);      // Confirmed secure
static const Color _processingBlue = Color(0xFF4B7BEC);   // Security operation in progress  
static const Color _warningAmber = Color(0xFFFFAA00);     // Requires attention
static const Color _dangerRed = Color(0xFFFF4757);        // Security risk or error
static const Color _neutralGray = Color(0xFF6B7A90);      // Inactive/neutral state
```

#### Security Color Usage Guidelines
- **Secure Green**: Successful PIN verification, completed encryption, validated shares
- **Processing Blue**: PIN entry in progress, encryption operation, share generation
- **Warning Amber**: PIN attempt warnings, threshold configuration alerts
- **Danger Red**: Authentication failures, invalid shares, critical errors
- **Neutral Gray**: Inactive states, disabled features, placeholder content

### Security Iconography

#### Trust-Building Icons
```dart
class SecurityIcons {
  static const IconData verified = Icons.verified_user;           // Verified operations
  static const IconData shield = Icons.shield;                   // General security
  static const IconData lock = Icons.lock;                       // Locked/secured state
  static const IconData lockOpen = Icons.lock_open;              // Unlocked/accessible
  static const IconData key = Icons.key;                         // Authentication
  static const IconData fingerprint = Icons.fingerprint;         // Biometric security
  static const IconData visibility = Icons.visibility;           // Show secure data
  static const IconData visibilityOff = Icons.visibility_off;    // Hide secure data
  static const IconData security = Icons.security;               // Security settings
  static const IconData warning = Icons.warning;                 // Security warnings
  static const IconData error = Icons.error;                     // Security errors
}
```

#### Icon Implementation Patterns
```dart
Widget buildSecurityIcon({
  required IconData icon,
  required SecurityState state,
  double size = 24,
}) {
  Color color;
  switch (state) {
    case SecurityState.secure:
      color = _secureGreen;
      break;
    case SecurityState.processing:
      color = _processingBlue;
      break;
    case SecurityState.warning:
      color = _warningAmber;
      break;
    case SecurityState.danger:
      color = _dangerRed;
      break;
    case SecurityState.neutral:
      color = _neutralGray;
      break;
  }

  return Icon(
    icon,
    color: color,
    size: size,
    semanticLabel: _getSecuritySemanticLabel(icon, state),
  );
}
```

## PIN Security Patterns

### Secure PIN Entry Interface

#### Visual Masking Strategy
The PIN input uses sophisticated visual masking to prevent shoulder surfing:

```dart
class SecurePinDots extends StatelessWidget {
  final int pinLength;
  final int maxLength;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilledDot = index < pinLength;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isFilledDot
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  )
                : null,
            border: Border.all(
              color: isFilledDot
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            boxShadow: isFilledDot
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
```

#### Security Progress Indicator
Visual feedback showing PIN entry progress without revealing length:

```dart
class SecurityProgressIndicator extends StatelessWidget {
  final int currentLength;
  final int minRequired;
  final int maxAllowed;
  
  @override
  Widget build(BuildContext context) {
    final progress = (currentLength / maxAllowed).clamp(0.0, 1.0);
    final isSecure = currentLength >= minRequired;
    
    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: isSecure
                      ? [_secureGreen, Color(0xFF00B380)]
                      : [_processingBlue, Color(0xFF3A6BDC)],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Security status text
        Text(
          isSecure ? 'SECURE LENGTH' : 'MINIMUM ${minRequired} DIGITS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: isSecure ? _secureGreen : _processingBlue,
          ),
        ),
      ],
    );
  }
}
```

#### Custom Security Keypad
Air-gapped keypad that prevents device keyboard access:

```dart
class SecureKeypad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final bool isEnabled;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
        children: [
          ..._buildNumberKeys(context),
          _buildSpecialKey(context, 'clear', Icons.clear_all_rounded),
          _buildNumberKey(context, '0'),
          _buildSpecialKey(context, 'backspace', Icons.backspace_outlined),
        ],
      ),
    );
  }

  Widget _buildNumberKey(BuildContext context, String number) {
    return SecureKeypadButton(
      onPressed: isEnabled ? () => onKeyPressed(number) : null,
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSpecialKey(BuildContext context, String action, IconData icon) {
    return SecureKeypadButton(
      onPressed: isEnabled ? () => onKeyPressed(action) : null,
      child: Icon(
        icon,
        size: 24,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
```

## Authentication State Visualization

### PIN Setup Flow Security

#### First-Time PIN Creation
```dart
class PinSetupSecurityIndicator extends StatelessWidget {
  final PinSetupStep currentStep;
  
  @override
  Widget build(BuildContext context) {
    return PremiumSecurityCard(
      showSecurityBadge: true,
      child: Column(
        children: [
          // Security shield icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _secureGreen.withValues(alpha: 0.2),
                  _secureGreen.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield,
              size: 32,
              color: _secureGreen,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _getStepTitle(currentStep),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            _getStepDescription(currentStep),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Step progress indicator
          _buildStepProgress(context, currentStep),
        ],
      ),
    );
  }
  
  String _getStepTitle(PinSetupStep step) {
    switch (step) {
      case PinSetupStep.create:
        return 'Create Your Secure PIN';
      case PinSetupStep.confirm:
        return 'Confirm Your PIN';
      case PinSetupStep.complete:
        return 'PIN Successfully Created';
    }
  }
}
```

### Authentication Failure Handling

#### Progressive Security Warnings
```dart
class AuthenticationFailureIndicator extends StatefulWidget {
  final int failureCount;
  final int maxAttempts;
  
  @override
  Widget build(BuildContext context) {
    final isNearLimit = failureCount >= (maxAttempts * 0.7);
    final isAtLimit = failureCount >= maxAttempts;
    
    Color indicatorColor;
    IconData indicatorIcon;
    String warningText;
    
    if (isAtLimit) {
      indicatorColor = _dangerRed;
      indicatorIcon = Icons.block;
      warningText = 'Access temporarily blocked';
    } else if (isNearLimit) {
      indicatorColor = _warningAmber;
      indicatorIcon = Icons.warning;
      warningText = '${maxAttempts - failureCount} attempts remaining';
    } else {
      indicatorColor = _neutralGray;
      indicatorIcon = Icons.info_outline;
      warningText = 'Enter your PIN to continue';
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            indicatorIcon,
            color: indicatorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warningText,
              style: TextStyle(
                color: indicatorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Data Security Visualization

### Secret Sharing Security Indicators

#### Share Generation Process
```dart
class ShareGenerationSecurityIndicator extends StatefulWidget {
  final int totalShares;
  final int threshold;
  final ShareGenerationState state;
  
  @override
  Widget build(BuildContext context) {
    return PremiumSecurityCard(
      title: 'Secure Share Generation',
      icon: Icons.security,
      child: Column(
        children: [
          // Visual representation of share distribution
          _buildShareVisualization(context),
          
          const SizedBox(height: 16),
          
          // Security threshold explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _processingBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _processingBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _processingBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Minimum $threshold of $totalShares shares required for reconstruction',
                    style: TextStyle(
                      fontSize: 12,
                      color: _processingBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Generation progress
          _buildGenerationProgress(context, state),
        ],
      ),
    );
  }
  
  Widget _buildShareVisualization(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(totalShares, (index) {
        final isRequired = index < threshold;
        
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRequired
                      ? [_secureGreen, Color(0xFF00B380)]
                      : [_neutralGray, Color(0xFF5A6578)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: (isRequired ? _secureGreen : _neutralGray)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRequired ? 'Required' : 'Extra',
              style: TextStyle(
                fontSize: 10,
                color: isRequired ? _secureGreen : _neutralGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }),
    );
  }
}
```

### Share Validation Security

#### Share Input Security Feedback
```dart
class ShareValidationIndicator extends StatelessWidget {
  final String shareValue;
  final ShareValidationState validationState;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getValidationColor(validationState).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getValidationColor(validationState).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getValidationIcon(validationState),
            color: _getValidationColor(validationState),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _getValidationMessage(validationState),
            style: TextStyle(
              fontSize: 12,
              color: _getValidationColor(validationState),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getValidationColor(ShareValidationState state) {
    switch (state) {
      case ShareValidationState.valid:
        return _secureGreen;
      case ShareValidationState.invalid:
        return _dangerRed;
      case ShareValidationState.validating:
        return _processingBlue;
      case ShareValidationState.empty:
        return _neutralGray;
    }
  }
  
  IconData _getValidationIcon(ShareValidationState state) {
    switch (state) {
      case ShareValidationState.valid:
        return Icons.check_circle;
      case ShareValidationState.invalid:
        return Icons.error;
      case ShareValidationState.validating:
        return Icons.hourglass_empty;
      case ShareValidationState.empty:
        return Icons.radio_button_unchecked;
    }
  }
}
```

## Trust-Building Visual Elements

### Security Badges and Certifications

#### Premium Security Badge
```dart
class PremiumSecurityBadge extends StatelessWidget {
  final String badgeText;
  final SecurityLevel level;
  
  @override
  Widget build(BuildContext context) {
    final badgeColor = _getSecurityLevelColor(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withValues(alpha: 0.2),
            badgeColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSecurityLevelIcon(level),
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Air-Gapped Security Indicators

#### Offline-Only Visual Cues
```dart
class AirGapSecurityIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _secureGreen.withValues(alpha: 0.1),
            _secureGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _secureGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Icon(
                Icons.wifi_off,
                color: _secureGreen,
                size: 20,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _secureGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIR-GAPPED SECURITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _secureGreen,
                  ),
                ),
                Text(
                  'All operations performed locally on your device',
                  style: TextStyle(
                    fontSize: 10,
                    color: _secureGreen.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Error Handling Security Patterns

### Secure Error Display

#### Privacy-Preserving Error Messages
```dart
class SecureErrorDisplay extends StatefulWidget {
  final String errorMessage;
  final ErrorSeverity severity;
  final bool isPinRelated;
  
  @override
  Widget build(BuildContext context) {
    // Sanitize error message to prevent information leakage
    final sanitizedMessage = _sanitizeErrorMessage(errorMessage, isPinRelated);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getErrorColor(severity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getErrorColor(severity).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getErrorIcon(severity),
            color: _getErrorColor(severity),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getErrorTitle(severity),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getErrorColor(severity),
                  ),
                ),
                if (sanitizedMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sanitizedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: _getErrorColor(severity),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Error dismissal button
          IconButton(
            onPressed: () => _dismissError(context),
            icon: Icon(
              Icons.close,
              color: _getErrorColor(severity),
              size: 18,
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }
  
  String _sanitizeErrorMessage(String message, bool isPinRelated) {
    if (isPinRelated) {
      // Never reveal specific PIN validation details
      return 'Please check your PIN and try again';
    }
    
    // Remove any potentially sensitive technical details
    return message.replaceAll(RegExp(r'[A-Fa-f0-9]{8,}'), '[REDACTED]');
  }
}
```

## Loading and Processing Security States

### Cryptographic Operation Indicators

#### Secure Processing Animation
```dart
class SecureProcessingIndicator extends StatefulWidget {
  final String operationTitle;
  final String operationDescription;
  final double? progress;
  
  @override
  Widget build(BuildContext context) {
    return PremiumSecurityCard(
      child: Column(
        children: [
          // Animated security shield
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animationController.value * 0.05),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _processingBlue.withValues(alpha: 0.3),
                        _processingBlue.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield,
                    size: 40,
                    color: _processingBlue,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            operationTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            operationDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Progress indicator
          if (progress != null) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: _processingBlue.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(_processingBlue),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}% Complete',
              style: TextStyle(
                fontSize: 12,
                color: _processingBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(_processingBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

## Implementation Guidelines

### Security-First Component Development

#### Checklist for Security UI Components
- [ ] **Visual Privacy**: No sensitive data visible in screenshots or screen recordings
- [ ] **Information Leakage**: Error messages don't reveal system internals
- [ ] **State Clarity**: Users always understand current security state
- [ ] **Action Confirmation**: Critical actions require explicit user confirmation
- [ ] **Accessibility Security**: Screen readers don't announce sensitive information
- [ ] **Visual Feedback**: All security operations provide appropriate visual feedback
- [ ] **Consistent Iconography**: Security icons maintain consistent meaning across app
- [ ] **Color Semantic Consistency**: Security colors maintain consistent meaning

#### Code Example: Secure Component Template
```dart
class SecureComponent extends StatefulWidget {
  final SecurityLevel requiredLevel;
  final Function(SecurityContext) onSecurityAction;
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Provide security context without revealing sensitive details
      label: 'Secure operation interface',
      hint: 'Requires authentication to proceed',
      excludeSemantics: true, // Prevent child semantics from leaking info
      child: PremiumSecurityCard(
        showSecurityBadge: true,
        child: Column(
          children: [
            // Always include security level indicator
            SecurityLevelIndicator(level: requiredLevel),
            
            const SizedBox(height: 16),
            
            // Component-specific content
            _buildSecureContent(context),
            
            const SizedBox(height: 16),
            
            // Secure action buttons
            _buildSecureActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureContent(BuildContext context) {
    // Implement secure content display
    // Never show sensitive data without user confirmation
    // Use progressive disclosure for complex security features
  }

  Widget _buildSecureActions(BuildContext context) {
    // Implement security action buttons
    // Always require explicit user interaction for critical actions
    // Provide clear feedback for all security state changes
  }
}
```

## Testing Security UI Patterns

### Security-Focused UI Testing

#### Test Security Visual States
```dart
group('Security UI Pattern Tests', () {
  testWidgets('PIN input prevents information leakage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SecurePinInput(
          onCompleted: (pin) {},
        ),
      ),
    );
    
    // Verify no actual PIN digits are displayed
    expect(find.text(RegExp(r'\d')), findsNothing);
    
    // Verify semantic labels don't reveal PIN content
    final semantics = tester.getSemantics(find.byType(SecurePinInput));
    expect(semantics.label, isNot(contains(RegExp(r'\d'))));
    
    // Verify filled dots are visually distinct but non-revealing
    final dots = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(SecurePinInput),
        matching: find.byType(Container),
      ),
    );
    
    // Should have visual differences but no text content
    expect(dots.length, greaterThan(0));
    for (final dot in dots) {
      expect(dot.child, isNot(isA<Text>()));
    }
  });

  testWidgets('Error messages are sanitized', (tester) async {
    const sensitiveError = 'PIN validation failed: hash mismatch 0x1234ABCD';
    
    await tester.pumpWidget(
      MaterialApp(
        home: SecureErrorDisplay(
          errorMessage: sensitiveError,
          isPinRelated: true,
        ),
      ),
    );
    
    // Verify sensitive details are not displayed
    expect(find.text(contains('hash')), findsNothing);
    expect(find.text(contains('0x1234ABCD')), findsNothing);
    
    // Verify generic security message is shown
    expect(find.text(contains('Please check your PIN')), findsOneWidget);
  });

  testWidgets('Security states have proper visual indicators', (tester) async {
    for (final state in SecurityState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: SecurityStateIndicator(state: state),
        ),
      );
      
      // Verify each state has distinct visual representation
      final indicator = tester.widget<Icon>(find.byType(Icon));
      final expectedColor = _getSecurityStateColor(state);
      
      expect(indicator.color, equals(expectedColor));
      
      // Verify semantic labeling
      final semantics = tester.getSemantics(find.byType(SecurityStateIndicator));
      expect(semantics.label, contains(_getSecurityStateLabel(state)));
    }
  });
});
```

## Future Security UI Enhancements

### Advanced Security Visualizations
1. **Biometric Integration Indicators**: Visual feedback for fingerprint/face authentication
2. **Hardware Security Module Indicators**: Visual confirmation of hardware-level security
3. **Quantum-Safe Cryptography Badges**: Future-proofing indicators for post-quantum security
4. **Multi-Party Security Visualization**: Visual representation of distributed security operations
5. **Zero-Knowledge Proof Indicators**: Visual feedback for privacy-preserving operations

### Enhanced Trust-Building Elements
- **Security Timeline Visualization**: Show security operation history
- **Cryptographic Algorithm Transparency**: Clear indication of security methods used
- **Device Security Health Indicators**: Real-time device security status
- **Threat Detection Visualization**: Security anomaly detection and display
- **Recovery Process Visualization**: Clear security incident recovery workflows

---

*This Security UI Patterns guide ensures that every visual element in SRSecrets reinforces user trust and security awareness while maintaining the premium crypto wallet aesthetic.*