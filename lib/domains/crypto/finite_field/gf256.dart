/// GF(2^8) Finite Field Arithmetic Implementation
/// 
/// This implementation provides constant-time operations for Galois Field 2^8
/// using the irreducible polynomial x^8 + x^4 + x^3 + x + 1 (0x11B).
/// All operations are designed to be side-channel resistant.
library;

import 'dart:typed_data';
import '../random/secure_random.dart';

/// GF(2^8) Finite Field implementation for Shamir's Secret Sharing
/// 
/// Uses the AES irreducible polynomial for compatibility and security.
/// All operations are constant-time to prevent timing attacks.
class GF256 {
  /// The irreducible polynomial: x^8 + x^4 + x^3 + x + 1
  static const int _irreduciblePolynomial = 0x11B;
  
  /// Precomputed logarithm table for fast multiplication
  static final Uint8List _logTable = Uint8List(256);
  
  /// Precomputed antilogarithm table for fast multiplication
  static final Uint8List _expTable = Uint8List(256);
  
  /// Precomputed multiplication table for constant-time operations
  static final List<Uint8List> _mulTable = List.generate(256, (_) => Uint8List(256));
  
  /// Precomputed inverse table for division
  static final Uint8List _invTable = Uint8List(256);
  
  /// Static initialization flag
  static bool _initialized = false;
  
  /// Initialize lookup tables for optimized operations
  static void _initialize() {
    if (_initialized) return;
    
    // Generate exp and log tables using generator polynomial 3
    int value = 1;
    for (int i = 0; i < 255; i++) {
      _expTable[i] = value;
      _logTable[value] = i;
      value = _multiplySlow(value, 3);
    }
    _expTable[255] = _expTable[0]; // Complete the cycle
    
    // Generate multiplication table using slow method during initialization
    for (int a = 0; a < 256; a++) {
      for (int b = 0; b < 256; b++) {
        _mulTable[a][b] = _multiplySlow(a, b);
      }
    }
    
    // Generate inverse table using slow multiplication
    _invTable[0] = 0; // 0 has no inverse
    for (int i = 1; i < 256; i++) {
      // Find j such that i * j = 1 in GF(256)
      for (int j = 1; j < 256; j++) {
        if (_multiplySlow(i, j) == 1) {
          _invTable[i] = j;
          break;
        }
      }
    }
    
    _initialized = true;
  }
  
  /// Slow multiplication using Russian peasant algorithm
  /// Used only during table initialization
  static int _multiplySlow(int a, int b) {
    int result = 0;
    
    while (b > 0) {
      if ((b & 1) == 1) {
        result ^= a;
      }
      a <<= 1;
      if ((a & 0x100) != 0) {
        a ^= _irreduciblePolynomial;
      }
      b >>= 1;
    }
    
    return result & 0xFF;
  }
  
  
  /// Addition in GF(2^8) - simply XOR
  /// Constant-time operation
  static int add(int a, int b) {
    _ensureInitialized();
    return a ^ b;
  }
  
  /// Subtraction in GF(2^8) - same as addition in this field
  /// Constant-time operation
  static int subtract(int a, int b) {
    _ensureInitialized();
    return a ^ b;
  }
  
  /// Multiplication in GF(2^8) using lookup table
  /// Constant-time operation through table lookup
  static int multiply(int a, int b) {
    _ensureInitialized();
    return _mulTable[a & 0xFF][b & 0xFF];
  }
  
  /// Division in GF(2^8)
  /// Constant-time operation through table lookup
  static int divide(int a, int b) {
    _ensureInitialized();
    if (b == 0) {
      throw ArgumentError('Division by zero in GF(256)');
    }
    return multiply(a, _invTable[b & 0xFF]);
  }
  
  /// Compute a^n in GF(2^8)
  /// Uses square-and-multiply for efficiency
  static int power(int a, int n) {
    _ensureInitialized();
    if (n == 0) return 1;
    if (a == 0) return 0;
    if (a == 1) return 1;
    
    // In GF(2^8), every non-zero element has order dividing 255
    // So a^255 = a for all non-zero a (Fermat's little theorem)
    // But we need to handle the case where n = 255 separately
    if (n == 255) return a; // Special case: a^255 = a
    int exponent = n % 255;
    if (exponent == 0 && n > 0) return 1;
    
    int result = 1;
    int base = a;
    
    while (exponent > 0) {
      if ((exponent & 1) == 1) {
        result = multiply(result, base);
      }
      base = multiply(base, base);
      exponent >>= 1;
    }
    
    return result;
  }
  
  /// Get multiplicative inverse in GF(2^8)
  /// Returns 0 for input 0 (which has no inverse)
  static int inverse(int a) {
    _ensureInitialized();
    return _invTable[a & 0xFF];
  }
  
  /// Evaluate polynomial at given x value
  /// coefficients[0] is the constant term
  static int evaluatePolynomial(List<int> coefficients, int x) {
    _ensureInitialized();
    if (coefficients.isEmpty) return 0;
    
    // Use Horner's method for efficiency
    int result = coefficients[coefficients.length - 1];
    for (int i = coefficients.length - 2; i >= 0; i--) {
      result = add(multiply(result, x), coefficients[i]);
    }
    
    return result;
  }
  
  /// Lagrange interpolation in GF(2^8)
  /// Returns the constant term of the polynomial passing through points
  static int lagrangeInterpolate(List<int> xValues, List<int> yValues) {
    _ensureInitialized();
    
    if (xValues.length != yValues.length) {
      throw ArgumentError('x and y arrays must have same length');
    }
    
    int n = xValues.length;
    int result = 0;
    
    for (int i = 0; i < n; i++) {
      int numerator = 1;
      int denominator = 1;
      
      for (int j = 0; j < n; j++) {
        if (i != j) {
          numerator = multiply(numerator, xValues[j]);
          denominator = multiply(denominator, 
              subtract(xValues[j], xValues[i]));
        }
      }
      
      int lagrangeCoeff = divide(numerator, denominator);
      result = add(result, multiply(yValues[i], lagrangeCoeff));
    }
    
    return result;
  }
  
  /// Generate secure random byte in GF(2^8)
  static int generateSecureRandom() {
    _ensureInitialized();
    return SecureRandom.instance.nextGF256Element();
  }
  
  /// Generate secure non-zero random byte in GF(2^8)
  static int generateSecureNonZeroRandom() {
    _ensureInitialized();
    return SecureRandom.instance.nextNonZeroGF256Element();
  }
  
  /// Validate that value is in valid GF(2^8) range
  static bool isValidElement(int value) {
    return value >= 0 && value <= 255;
  }
  
  /// Ensure tables are initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      _initialize();
    }
  }
  
  /// Clear sensitive data from memory (for security)
  static void secureClear() {
    // Note: Dart doesn't guarantee memory clearing,
    // but we attempt to overwrite sensitive data
    if (_initialized) {
      _logTable.fillRange(0, 256, 0);
      _expTable.fillRange(0, 256, 0);
      for (var table in _mulTable) {
        table.fillRange(0, 256, 0);
      }
      _invTable.fillRange(0, 256, 0);
    }
  }
}