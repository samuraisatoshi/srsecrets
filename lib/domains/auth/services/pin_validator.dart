/// PIN Validator
///
/// Single Responsibility: Validates PIN against security requirements.
/// Extracted from PinServiceImpl to comply with SRP.
library;

import 'pin_service.dart';

/// Interface for PIN validation operations
abstract class IPinValidator {
  /// Validates a PIN against security requirements
  /// Throws [PinValidationException] if validation fails
  void validate(String pin, PinRequirements requirements);
}

/// Default implementation of PIN validator
class PinValidator implements IPinValidator {
  const PinValidator();

  @override
  void validate(String pin, PinRequirements requirements) {
    List<String> violations = [];

    // Check length requirements
    if (pin.length < requirements.minLength) {
      violations.add('PIN must be at least ${requirements.minLength} characters');
    }

    if (pin.length > requirements.maxLength) {
      violations.add('PIN must be no more than ${requirements.maxLength} characters');
    }

    // Check digits only requirement
    if (requirements.requireDigitsOnly) {
      RegExp digitsOnly = RegExp(r'^\d+$');
      if (!digitsOnly.hasMatch(pin)) {
        violations.add('PIN must contain only digits');
      }
    }

    // Check for common patterns
    if (requirements.preventCommonPatterns) {
      _validateCommonPatterns(pin, violations);
    }

    // Check for repeating digits
    if (requirements.preventRepeatingDigits) {
      _validateRepeatingDigits(pin, violations);
    }

    // Check for sequential digits
    if (requirements.preventSequentialDigits) {
      _validateSequentialDigits(pin, violations);
    }

    if (violations.isNotEmpty) {
      throw PinValidationException(
        message: 'PIN validation failed',
        violations: violations,
      );
    }
  }

  /// Validate against common PIN patterns
  void _validateCommonPatterns(String pin, List<String> violations) {
    // List of common weak PINs (including 4-digit ones)
    const List<String> commonPins = [
      // 4-digit common PINs
      '0000', '1111', '2222', '3333', '4444', '5555', '6666', '7777', '8888', '9999',
      '1234', '4321', '1212', '2580', '0852', '1010', '2468', '1357',
      // 5-digit common PINs
      '12345', '54321', '11111', '00000',
      // 6-digit common PINs
      '123456', '654321', '111111', '000000', '123123',
      '121212', '101010', '555555', '987654', '246810',
      '135791', '112233',
    ];

    if (commonPins.contains(pin)) {
      violations.add('PIN is too common and easily guessed');
    }

    // Check for birthday patterns (DDMM, MMDD, MMYY, YYYY)
    if (pin.length == 4) {
      // For 4-digit PINs, check for year patterns (1900-2099) and simple date patterns
      RegExp yearPattern = RegExp(r'^(19|20)\d{2}$');
      RegExp datePattern = RegExp(r'^(0[1-9]|[12][0-9]|3[01])(0[1-9]|1[0-2])$|^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$');
      if (yearPattern.hasMatch(pin) || datePattern.hasMatch(pin)) {
        violations.add('PIN appears to be a date pattern');
      }
    } else if (pin.length >= 6) {
      // For longer PINs, check for more complex date patterns
      RegExp birthdayPattern = RegExp(r'^(0[1-9]|[12][0-9]|3[01])(0[1-9]|1[0-2])\d{2}$|^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])\d{2}$');
      if (birthdayPattern.hasMatch(pin)) {
        violations.add('PIN appears to be a date pattern');
      }
    }
  }

  /// Validate against repeating digits
  void _validateRepeatingDigits(String pin, List<String> violations) {
    // Check for all same digits
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) {
      violations.add('PIN cannot contain only repeating digits');
    }

    // Check for excessive repetition (more than 2 consecutive same digits)
    if (RegExp(r'(\d)\1{2,}').hasMatch(pin)) {
      violations.add('PIN cannot contain more than 2 consecutive identical digits');
    }
  }

  /// Validate against sequential digits
  void _validateSequentialDigits(String pin, List<String> violations) {
    if (pin.length < 3) return; // Too short for meaningful sequence check

    // Check for ascending sequences
    bool hasAscending = _hasSequence(pin, ascending: true);
    bool hasDescending = _hasSequence(pin, ascending: false);

    if (hasAscending || hasDescending) {
      violations.add('PIN cannot contain sequential digits');
    }
  }

  /// Check if PIN contains sequential digits
  bool _hasSequence(String pin, {required bool ascending}) {
    for (int i = 0; i < pin.length - 2; i++) {
      int first = int.parse(pin[i]);
      int second = int.parse(pin[i + 1]);
      int third = int.parse(pin[i + 2]);

      if (ascending) {
        if (second == first + 1 && third == second + 1) {
          return true;
        }
      } else {
        if (second == first - 1 && third == second - 1) {
          return true;
        }
      }
    }

    return false;
  }
}
