import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility class for accessibility testing and validation
class AccessibilityUtils {
  
  /// Calculates color contrast ratio between two colors
  /// Returns a value from 1:1 (no contrast) to 21:1 (maximum contrast)
  static double calculateContrastRatio(Color foreground, Color background) {
    final luminance1 = _calculateLuminance(foreground);
    final luminance2 = _calculateLuminance(background);
    
    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Calculates relative luminance of a color according to WCAG standards
  static double _calculateLuminance(Color color) {
    // Convert to sRGB values
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);
    
    // Calculate relative luminance
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// Linearizes a color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
  
  /// Validates if contrast ratio meets WCAG 2.1 AA standards
  /// Normal text: 4.5:1, Large text: 3:1
  static bool meetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final threshold = isLargeText ? 3.0 : 4.5;
    return ratio >= threshold;
  }
  
  /// Validates if contrast ratio meets WCAG 2.1 AAA standards
  /// Normal text: 7:1, Large text: 4.5:1
  static bool meetsContrastRequirementAAA(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final threshold = isLargeText ? 4.5 : 7.0;
    return ratio >= threshold;
  }
  
  /// Validates minimum touch target size (44x44 dp according to WCAG)
  static bool meetsTouchTargetSize(Size size) {
    const minSize = 44.0;
    return size.width >= minSize && size.height >= minSize;
  }
  
  /// Generates an accessibility audit report for theme colors
  static AccessibilityAuditReport auditThemeColors(ColorScheme colorScheme) {
    final results = <ColorContrastResult>[];
    
    // Primary color combinations
    results.add(_auditColorPair(
      'Primary on Surface',
      colorScheme.primary,
      colorScheme.surface,
    ));
    
    results.add(_auditColorPair(
      'On Primary Container on Primary Container',
      colorScheme.onPrimaryContainer,
      colorScheme.primaryContainer,
    ));
    
    // Secondary color combinations
    results.add(_auditColorPair(
      'Secondary on Surface',
      colorScheme.secondary,
      colorScheme.surface,
    ));
    
    results.add(_auditColorPair(
      'On Secondary Container on Secondary Container',
      colorScheme.onSecondaryContainer,
      colorScheme.secondaryContainer,
    ));
    
    // Error color combinations
    results.add(_auditColorPair(
      'Error on Surface',
      colorScheme.error,
      colorScheme.surface,
    ));
    
    results.add(_auditColorPair(
      'On Error Container on Error Container',
      colorScheme.onErrorContainer,
      colorScheme.errorContainer,
    ));
    
    // Surface color combinations
    results.add(_auditColorPair(
      'On Surface on Surface',
      colorScheme.onSurface,\n      colorScheme.surface,
    ));
    
    results.add(_auditColorPair(
      'On Background on Background',
      colorScheme.onBackground,
      colorScheme.background,
    ));
    
    // Outline colors
    results.add(_auditColorPair(
      'Outline on Surface',
      colorScheme.outline,
      colorScheme.surface,
    ));
    
    return AccessibilityAuditReport(
      colorContrastResults: results,
      overallPassed: results.every((result) => result.passesAA),
    );
  }
  
  /// Audits a specific color pair
  static ColorContrastResult _auditColorPair(
    String description,
    Color foreground,
    Color background,
  ) {
    final ratio = calculateContrastRatio(foreground, background);
    return ColorContrastResult(
      description: description,
      foregroundColor: foreground,
      backgroundColor: background,
      contrastRatio: ratio,
      passesAA: ratio >= 4.5,
      passesAAA: ratio >= 7.0,
    );
  }
  
  /// Generates semantic labels for screen reader testing
  static List<String> generateScreenReaderTestLabels() {
    return [
      'PIN entry: 0 of 8 digits entered',
      'Enter digit 1',
      'Clear all digits',
      'Delete last digit',
      'Error: Invalid PIN',
      'Secret name input',
      'Share input 1',
      'Add another share input',
      'Create secret shares',
      'Reconstruct secret from shares',
      'Dismiss error message',
    ];
  }
  
  /// Validates semantic properties for accessibility
  static bool validateSemanticProperties(
    String? label,
    String? hint,
    bool? isButton,
    bool? isTextField,
  ) {
    // Button should have label
    if (isButton == true && (label == null || label.isEmpty)) {
      return false;
    }
    
    // Text field should have label or hint
    if (isTextField == true && 
        (label == null || label.isEmpty) && 
        (hint == null || hint.isEmpty)) {
      return false;
    }
    
    return true;
  }
}

/// Result of a color contrast audit
class ColorContrastResult {
  final String description;
  final Color foregroundColor;
  final Color backgroundColor;
  final double contrastRatio;
  final bool passesAA;
  final bool passesAAA;
  
  const ColorContrastResult({
    required this.description,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.contrastRatio,
    required this.passesAA,
    required this.passesAAA,
  });
  
  @override
  String toString() {
    final status = passesAA ? (passesAAA ? 'AAA ✓' : 'AA ✓') : 'FAIL ✗';
    return '$description: ${contrastRatio.toStringAsFixed(2)}:1 ($status)';
  }
}

/// Complete accessibility audit report
class AccessibilityAuditReport {
  final List<ColorContrastResult> colorContrastResults;
  final bool overallPassed;
  
  const AccessibilityAuditReport({
    required this.colorContrastResults,
    required this.overallPassed,
  });
  
  /// Get summary of audit results
  String getSummary() {
    final totalTests = colorContrastResults.length;
    final passedAA = colorContrastResults.where((r) => r.passesAA).length;
    final passedAAA = colorContrastResults.where((r) => r.passesAAA).length;
    
    return '''
Accessibility Audit Summary
==========================
Total color combinations tested: $totalTests
WCAG 2.1 AA compliance: $passedAA/$totalTests (${(passedAA/totalTests*100).toInt()}%)
WCAG 2.1 AAA compliance: $passedAAA/$totalTests (${(passedAAA/totalTests*100).toInt()}%)
Overall AA Status: ${overallPassed ? 'PASS ✓' : 'FAIL ✗'}

Detailed Results:
${colorContrastResults.map((r) => '  ${r.toString()}').join('\\n')}
''';
  }
  
  /// Get failed tests only
  List<ColorContrastResult> getFailedTests() {
    return colorContrastResults.where((r) => !r.passesAA).toList();
  }
}